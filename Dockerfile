ARG PUID=1000
ARG PGID=1000
ARG USERNAME=appuser

ARG ROOT_PATH=/app
# Changing USER_DATA_PATH will break things
ARG USER_DATA_PATH=/etc/cloudymc/data
ARG PYTHON_VENV_PATH=/opt/venv
ARG ANSIBLE_COLLECTIONS_PATH=/usr/share/ansible
ARG TF_PLUGIN_CACHE_PATH=/var/cache/terraform/plugin-cache

# ======================= Base =======================
FROM docker.io/library/python:3.13-slim-trixie AS base
ARG PUID
ARG PGID
ARG USERNAME
ARG ROOT_PATH
ARG USER_DATA_PATH
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
RUN mkdir -p ${USER_DATA_PATH} \
	&& chown ${USERNAME}:${USERNAME} ${USER_DATA_PATH}

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV USER_DATA_PATH=${USER_DATA_PATH} \
	TF_PLUGIN_CACHE_PATH=${TF_PLUGIN_CACHE_PATH}


# ======================= Terraform =======================
FROM base AS terraform
ARG TF_VERSION=1.14.7
ARG TF_LINT_VERSION=v0.61.0

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	unzip wget \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,target=/terraform.zip \
	--mount=type=cache,target=/tflint.zip \
	wget -q https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip \
	-O terraform.zip \
	&& unzip -q terraform.zip terraform -d /usr/local/bin \
	&& chmod +x /usr/local/bin/terraform \
	&& wget -q https://github.com/terraform-linters/tflint/releases/download/${TF_LINT_VERSION}/tflint_linux_amd64.zip \
	-O tflint.zip \
	&& unzip -q tflint.zip tflint -d /usr/local/bin \
	&& chmod +x /usr/local/bin/tflint

# Terraform copies files from the cache into local .terraform directory
# so it needs to be baked into the image itself
RUN --mount=type=cache,target=/tmp/tf-cache \
	--mount=type=bind,target=./terraform,Z \
	mkdir -p ${TF_PLUGIN_CACHE_PATH} \
	&& cp -rn /tmp/tf-cache/. ${TF_PLUGIN_CACHE_PATH}/ 2>/dev/null || true \
	&& cd ./terraform && terraform init -input=false \
	&& cp -rn ${TF_PLUGIN_CACHE_PATH}/. /tmp/tf-cache/ 2>/dev/null || true


# ======================= Python =======================
FROM base as python
ARG USERNAME
ARG PYTHON_VENV_PATH

ENV PYTHON_VENV_PATH=${PYTHON_VENV_PATH} \
	PATH="${PYTHON_VENV_PATH}/bin:${PATH}"
RUN --mount=type=bind,source=./backend/requirements/common.txt,target=./backend/requirements/common.txt \
	--mount=type=cache,target=/root/.cache/pip \
	python3 -m venv ${PYTHON_VENV_PATH} \
	&& pip install -r ./backend/requirements/common.txt \
	&& chown ${USERNAME}:${USERNAME} ${PYTHON_VENV_PATH}


# ======================= Ansible =======================
FROM python as ansible
ARG USERNAME
ARG ANSIBLE_COLLECTIONS_PATH

# Ansible sources files from the collections directory
# so it needs to be baked into the image itself
ENV ANSIBLE_COLLECTIONS_PATH=${ANSIBLE_COLLECTIONS_PATH}
RUN --mount=type=bind,source=./ansible/requirements.yml,target=./ansible/requirements.yml,Z \
	--mount=type=cache,target=/tmp/ansible \
	mkdir -p ${ANSIBLE_COLLECTIONS_PATH} \
	cp -rn /tmp/ansible/. ${ANSIBLE_COLLECTIONS_PATH}/ 2>/dev/null || true \
	&& cd ./ansible && ansible-galaxy collection install --no-deps -r ./requirements.yml \
	&& cp -rn ${ANSIBLE_COLLECTIONS_PATH}/. /tmp/ansible/ 2>/dev/null || true \
	&& chown -R ${USERNAME}:${USERNAME} ${ANSIBLE_COLLECTIONS_PATH}


# ======================= Development =======================
FROM ansible AS dev
ARG USERNAME

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

COPY --link --from=terraform /usr/local/bin/terraform /usr/local/bin/terraform
COPY --link --from=terraform /usr/local/bin/tflint /usr/local/bin/tflint
COPY --link --from=terraform ${TF_PLUGIN_CACHE_PATH} ${TF_PLUGIN_CACHE_PATH}

RUN --mount=type=bind,source=./backend/requirements/common.txt,target=./backend/requirements/common.txt \
	--mount=type=bind,source=./backend/requirements/dev.txt,target=./backend/requirements/dev.txt \
	--mount=type=cache,target=/root/.cache/pip \
	pip install -r ./backend/requirements/dev.txt

RUN --mount=type=cache,target=/root/.npm \
	--mount=type=bind,source=./frontend/package.json,target=./frontend/package.json,Z \
	--mount=type=bind,source=./frontend/package-lock.json,target=./frontend/package-lock.json,Z \
	cd ./frontend && npm ci --no-audit --no-fund \
	&& chown -R ${USERNAME}:${USERNAME} ./node_modules

USER ${USERNAME}
EXPOSE 5173
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
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
ARG ROOT_PATH
ARG USER_DATA_PATH

RUN --mount=type=bind,source=./backend/requirements/common.txt,target=./backend/requirements/common.txt \
	--mount=type=bind,source=./backend/requirements/prod.txt,target=./backend/requirements/prod.txt \
	--mount=type=cache,target=/root/.cache/pip \
	pip install -r ./backend/requirements/prod.txt

COPY --link --from=terraform ${TF_PLUGIN_CACHE_PATH} ${TF_PLUGIN_CACHE_PATH}
COPY --link --from=terraform /usr/local/bin/terraform /usr/local/bin/terraform

COPY ./backend/ ./backend
COPY --link --from=node-build ${ROOT_PATH}/frontend/dist ./backend/app/static
COPY ./ansible ./ansible
COPY ./terraform ./terraform

RUN cd ./terraform && terraform init
RUN chown -R ${USERNAME}:${USERNAME} ./

USER ${USERNAME}
EXPOSE 8000
VOLUME ${USER_DATA_PATH}
WORKDIR ${ROOT_PATH}/backend
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["gunicorn", "-w", "1", "-k", "gthread", "--threads", "2", "-b", "0:8000", "app:app"]
