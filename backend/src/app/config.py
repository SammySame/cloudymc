import os

from app import MODULE_ROOT_PATH, PROJECT_ROOT_PATH

CONFIG_PATH = os.path.join(PROJECT_ROOT_PATH, 'config', 'user')
TF_PATH = os.path.join(PROJECT_ROOT_PATH, 'terraform')
TF_VARS_PATH = os.path.join(PROJECT_ROOT_PATH, 'terraform', 'terraform.tfvars.json')
TF_VARS_MAP_PATH = os.path.join(MODULE_ROOT_PATH, 'data', 'terraform_oci_map.json')
ANSIBLE_PATH = os.path.join(PROJECT_ROOT_PATH, 'ansible')
ANSIBLE_MAP_PATH = os.path.join(MODULE_ROOT_PATH, 'data', 'ansible_map.json')
