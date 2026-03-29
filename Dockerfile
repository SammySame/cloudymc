ARG BASE_IMAGE=docker.io/library/python:3.13-slim-trixie
ARG PUID=1000
ARG PGID=1000
ARG USERNAME=appuser

ARG ROOT_PATH=/app
ARG SSH_KEYS_PATH=/opt/ssh_keys
ARG ANSIBLE_COLLECTIONS_PATH=/usr/share/ansible/collections
ARG TF_PLUGIN_CACHE_PATH=/usr/share/terraform/plugin-cache


# ======================= Dependencies =======================
FROM ${BASE_IMAGE} AS deps
ARG TF_VERSION=1.14.7
ARG TF_LINT_VERSION=v0.61.0

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


# ======================= Base =======================
FROM ${BASE_IMAGE} AS base
ARG PUID
ARG PGID
ARG USERNAME
ARG ROOT_PATH
ARG SSH_KEYS_PATH
ARG ANSIBLE_COLLECTIONS_PATH
ARG TF_PLUGIN_CACHE_PATH

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	openssh-client \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN groupadd -g ${PGID} ${USERNAME} \
	&& useradd -u ${PUID} -g ${PGID} -m -s /bin/bash ${USERNAME}

WORKDIR ${ROOT_PATH}

RUN mkdir -p ${SSH_KEYS_PATH} ${ANSIBLE_COLLECTIONS_PATH} ${TF_PLUGIN_CACHE_PATH}

# Terraform
COPY --link --from=deps /usr/local/bin/terraform /usr/local/bin/terraform
COPY ./terraform ./terraform
ENV TF_PLUGIN_CACHE_DIR=${TF_PLUGIN_CACHE_PATH}
RUN --mount=type=cache,target=/tmp/tf-cache \
	cp -rn /tmp/tf-cache/. ${TF_PLUGIN_CACHE_PATH}/ 2>/dev/null || true \
	&& cd ./terraform && terraform init -input=false \
	&& cp -rn ${TF_PLUGIN_CACHE_PATH}/. /tmp/tf-cache/ 2>/dev/null || true

# Python
ENV PYTHON_VENV_PATH=/opt/venv \
	PATH="${PYTHON_VENV_PATH}/bin:${PATH}"
# Copy source files as separate step so that the build cache is not invalidated on changes
COPY ./backend/requirements/common.txt ./backend/requirements/common.txt
RUN --mount=type=cache,target=/root/.cache/pip \
	python3 -m venv ${PYTHON_VENV_PATH} \
	&& pip install -r ./backend/requirements/common.txt
COPY ./backend/ ./backend
RUN pip install -e ./backend

# Ansible
COPY ./ansible/requirements.yml ./ansible/requirements.yml
ENV ANSIBLE_COLLECTIONS_PATH=${ANSIBLE_COLLECTIONS_PATH}
RUN cd ./ansible \
	&& ansible-galaxy collection install --no-deps -r ./requirements.yml


# ======================= Development =======================
FROM base AS dev
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

# Terraform
ENV TF_PLUGIN_CACHE_DIR=${TF_PLUGIN_CACHE_PATH}
COPY --link --from=deps /usr/local/bin/tflint /usr/local/bin/tflint

# Python
ENV PYTHON_VENV_PATH=/opt/venv \
	PATH="${PYTHON_VENV_PATH}/bin:${PATH}"
RUN --mount=type=cache,target=/root/.cache/pip \
	pip install -r ./backend/requirements/dev.txt

# npm
RUN --mount=type=cache,target=/root/.npm \
	--mount=type=bind,source=./frontend/package.json,target=./frontend/package.json,Z \
	--mount=type=bind,source=./frontend/package-lock.json,target=./frontend/package-lock.json,Z \
	cd ./frontend && npm ci --no-audit --no-fund \
	&& chown -R ${USERNAME}:${USERNAME} ./node_modules

# Ansible
ENV ANSIBLE_COLLECTIONS_PATH=${ANSIBLE_COLLECTIONS_PATH}

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
RUN --mount=type=bind,target=./frontend,Z \
	npm run build


# ======================= Production =======================
FROM base AS prod
ARG USERNAME
ARG TF_PLUGIN_CACHE_PATH

ENV TF_PLUGIN_CACHE_DIR=${TF_PLUGIN_CACHE_PATH} \
	ANSIBLE_COLLECTIONS_PATH=${ANSIBLE_COLLECTIONS_PATH}

ENV PYTHON_VENV_PATH=/opt/venv \
	PATH="${PYTHON_VENV_PATH}/bin:${PATH}"
RUN --mount=type=cache,target=/root/.cache/pip \
	pip install -r ./backend/requirements/prod.txt

COPY --link --from=node-build ./frontend/dist ./frontend/dist
COPY ./ansible ./config ./

USER ${USERNAME}
EXPOSE 8000
VOLUME [
	"${ROOT_PATH}/terraform/terraform.tfstate",
	"${ROOT_PATH}/terraform/terraform.tfstate.backup"
]
CMD ["gunicorn", "-w", "4", "-b", "0:8000", "backend.src.app:app"]
