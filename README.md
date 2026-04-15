<h1 align="center">CloudyMC</h1>
<h3 align="center">Automated Minecraft Server Creation in Cloud</h3>
<p align="center">
<img alt="GPL 3.0 License" src="https://img.shields.io/github/license/SammySame/cloudymc">
<img alt="Python" src="https://img.shields.io/badge/Python-white?logo=Python">
<img alt="TypeScript" src="https://img.shields.io/badge/TypeScript-white?logo=TypeScript">
<img alt="React" src="https://img.shields.io/badge/React-white?logoColor=black&logo=React">
<img alt="Terraform" src="https://img.shields.io/badge/Terraform-white?logo=Terraform">
<img alt="Ansible" src="https://img.shields.io/badge/Ansible-white?logoColor=black&logo=Ansible">
</p>

---

CloudyMC is a combination of infrastructure automation software packaged into a container and presented as a simple web form where most of the configuration happens. It avoids the cumbersome manual setup of a cloud instance.

> [!IMPORTANT]
> This project should be treated as an easy way to kickstart a Minecraft server in the cloud. Unless you only need very basic setup, you might get away with using just the web form. But for a long running Minecraft server, it's for the best to create the cloud instance through the web form once, and then provision it manually by direct access into instance via STFP or SSH.


<details>

<summary> Media </summary>
<img width="500" height="720" alt="cloudymc_web_interface_02" src="https://github.com/user-attachments/assets/6e237683-739d-4f38-a579-70529f6d9cbe" />
<img width="500" height="720" alt="cloudymc_web_interface_01" src="https://github.com/user-attachments/assets/cd902977-a3e2-4e7c-89e5-d6f4b0bd4182" />

If you want to see it in action, see this video showcase https://github.com/user-attachments/assets/4b0441cb-b19b-4bdd-a9fb-a5e72f9c989a

</details>

## Features

- Ability to configure all the important Minecraft server settings
- Configuration happens through an intuitive web interface
- Light and dark mode in the web form
- Advanced form validation that highlights user made errors
- Apply changes, test them and remove all the cloud instance resources in a click of a button
- Persistent web form configuration living inside JSON file
- Enables SFTP in a chroot, which allows for secure upload, download, and modification of server files
- Uses non-root user inside the container by default

## Supported Cloud Providers

- **Oracle Cloud Infrastructure** (supports free tier mode)

## Requirements

- Docker or Podman installed on the user system
- Working account for one of the supported cloud providers
- Two SSH key pairs for the cloud instance users and SFTP access
- Working internet connection and a web browser

## Getting started

For installation guide, see [CloudyMC Installation Guide](docs/installation.md).

For advanced configuration (e.g. modded servers), see [Minecraft Server Configuration](docs/advanced.md).

For Podman users, see [rootless Podman Quadlet Installation](docs/podman.md).

## Acknowledgments

Shoutout to all the developers being involved in the creation of the software used in this project, and especially [itzg](https://github.com/itzg) with their fantastic [docker-minecraft-server](https://github.com/itzg/docker-minecraft-server) container image that is used on the cloud instance.
