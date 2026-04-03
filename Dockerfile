ARG PUID=1000
ARG PGID=1000
ARG USERNAME=appuser

ARG ROOT_PATH=/app
ARG USER_DATA_PATH=/etc/cloudymc/data
# Changing SSH_KEYS_PATH will break things
ARG SSH_KEYS_PATH=/opt/ssh_keys
ARG PYTHON_VENV_PATH=/opt/venv
ARG ANSIBLE_COLLECTIONS_PATH=/usr/share/ansible/collections
ARG TF_PLUGIN_CACHE_PATH=/usr/share/terraform/plugin-cache

# ======================= Base =======================
FROM docker.io/library/python:3.13-slim-trixie AS base
ARG PUID
ARG PGID
ARG USERNAME
ARG ROOT_PATH
ARG USER_DATA_PATH
ARG SSH_KEYS_PATH
ARG ANSIBLE_COLLECTIONS_PATH
ARG TF_PLUGIN_CACHE_PATH

LABEL org.opencontainers.image.title="cloudymc"
LABEL org.opencontainers.image.description="Run Minecraft servers in cloud!"
# LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.authors="SammySame"

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	openssh-client \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN groupadd -g ${PGID} ${USERNAME} \
	&& useradd -u ${PUID} -g ${PGID} -m -s /bin/bash ${USERNAME}

WORKDIR ${ROOT_PATH}
RUN mkdir -p ${SSH_KEYS_PATH} ${ANSIBLE_COLLECTIONS_PATH} ${TF_PLUGIN_CACHE_PATH} ${USER_DATA_PATH} \
	&& chown 755 ${SSH_KEYS_PATH} ${USER_DATA_PATH}

ENV USER_DATA_PATH=${USER_DATA_PATH} \
	SSH_KEYS_PATH=${SSH_KEYS_PATH}


# ======================= Terraform =======================
FROM base AS terraform
ARG TF_VERSION=1.14.7
ARG TF_LINT_VERSION=v0.61.0
ARG TF_PLUGIN_CACHE_PATH

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	unzip wget \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN wget -q https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip \
	-O terraform.zip \
	&& unzip -q terraform.zip terraform -d /usr/local/bin \
	&& rm -f terraform.zip \
	&& chmod +x /usr/local/bin/terraform \
	&& wget -q https://github.com/terraform-linters/tflint/releases/download/${TF_LINT_VERSION}/tflint_linux_amd64.zip \
	-O tflint.zip \
	&& unzip -q tflint.zip tflint -d /usr/local/bin \
	&& rm -f tflint.zip \
	&& chmod +x /usr/local/bin/tflint

ENV TF_PLUGIN_CACHE_PATH=${TF_PLUGIN_CACHE_PATH}
# Terraform copies from the cache into the .terraform directory, so the files are copied into the image itself
RUN --mount=type=cache,target=/tmp/tf-cache \
	--mount=type=bind,target=./terraform,Z \
	cp -rn /tmp/tf-cache/. ${TF_PLUGIN_CACHE_PATH}/ 2>/dev/null || true \
	&& cd ./terraform && terraform init -input=false \
	&& cp -rn ${TF_PLUGIN_CACHE_PATH}/. /tmp/tf-cache/ 2>/dev/null || true


# ======================= Python =======================
FROM base as python
ARG PYTHON_VENV_PATH

ENV PYTHON_VENV_PATH=${PYTHON_VENV_PATH} \
	PATH="${PYTHON_VENV_PATH}/bin:${PATH}"
COPY ./backend/requirements/common.txt ./backend/requirements/common.txt
RUN --mount=type=cache,target=/root/.cache/pip \
	python3 -m venv ${PYTHON_VENV_PATH} \
	&& pip install -r ./backend/requirements/common.txt

COPY ./backend/ ./backend
RUN pip install -e ./backend


# ======================= Ansible =======================
FROM python as ansible
ARG ANSIBLE_COLLECTIONS_PATH

COPY ./ansible/requirements.yml ./ansible/requirements.yml
ENV ANSIBLE_COLLECTIONS_PATH=${ANSIBLE_COLLECTIONS_PATH}
RUN cd ./ansible && ansible-galaxy collection install --no-deps -r ./requirements.yml


# ======================= Development =======================
FROM ansible AS dev
ARG USERNAME
ARG TF_PLUGIN_CACHE_PATH

# VS Code requires en_US.UTF-8 locale for the pre-commit hooks
# https://github.com/microsoft/vscode/issues/189924
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	git nodejs npm locales \
	&& echo en_US.UTF-8 UTF-8 >> /etc/locale.gen \
	&& locale-gen \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

ENV TF_PLUGIN_CACHE_PATH=${TF_PLUGIN_CACHE_PATH}
COPY --link --from=terraform /usr/local/bin/terraform /usr/local/bin/terraform
COPY --link --from=terraform /usr/local/bin/tflint /usr/local/bin/tflint
COPY --link --from=terraform ${TF_PLUGIN_CACHE_PATH} ${TF_PLUGIN_CACHE_PATH}

RUN --mount=type=cache,target=/root/.cache/pip \
	pip install -r ./backend/requirements/dev.txt

RUN --mount=type=cache,target=/root/.npm \
	--mount=type=bind,source=./frontend/package.json,target=./frontend/package.json,Z \
	--mount=type=bind,source=./frontend/package-lock.json,target=./frontend/package-lock.json,Z \
	cd ./frontend && npm ci --no-audit --no-fund \
	&& chown -R ${USERNAME}:${USERNAME} ./node_modules

USER ${USERNAME}
EXPOSE 5173
CMD ["sleep", "infinity"]


# ======================= Node Build =======================
FROM docker.io/library/node:20-alpine AS node-build
ARG ROOT_PATH

WORKDIR ${ROOT_PATH}

RUN --mount=type=cache,target=/root/.npm \
	--mount=type=bind,source=./frontend/package.json,target=./frontend/package.json,Z \
	--mount=type=bind,source=./frontend/package-lock.json,target=./frontend/package-lock.json,Z \
	cd ./frontend && npm ci --no-audit --no-fund
COPY ./frontend/. ./frontend
RUN cd ./frontend && npm run build


# ======================= Production =======================
FROM ansible AS prod
ARG USERNAME
ARG TF_PLUGIN_CACHE_PATH

RUN --mount=type=cache,target=/root/.cache/pip \
	pip install -r ./backend/requirements/prod.txt

ENV TF_PLUGIN_CACHE_PATH=${TF_PLUGIN_CACHE_PATH}
COPY --link --from=terraform ${TF_PLUGIN_CACHE_PATH} ${TF_PLUGIN_CACHE_PATH}

COPY --link --from=node-build ./frontend/dist ./frontend/dist
COPY ./ansible ./config ./terraform ./

RUN find ${ROOT_PATH} -type d -print0 | xargs -0 chmod 755 \
	&& find ${ROOT_PATH} -type f -print0 | xargs -0 chmod 644

USER ${USERNAME}
EXPOSE 8000
VOLUME [
	"${ROOT_PATH}/terraform/terraform.tfstate",
	"${ROOT_PATH}/terraform/terraform.tfstate.backup",
	"${USER_DATA_PATH}"
]
CMD ["gunicorn", "-w", "4", "-b", "0:8000", "backend.src.app:app"]
