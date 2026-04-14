# CloudyMC Installation Guide

## Install Docker and Docker Compose

Follow the official Docker documentation for your specific operating system for either [Docker Desktop](https://docs.docker.com/desktop/) or [Docker](https://docs.docker.com/engine/install/). If you are unfamilliar with Docker, install Docker Deskstop, as it offers a graphical user interface and is easier to install.

If you installed Docker Dekstop, then you already have Docker Compose, if you didn't, then follow the official [Docker Compose installation](https://docs.docker.com/compose/install/#install-compose) page.

To learn more about Docker, read and watch the official [intrudictionary material](https://docs.docker.com/get-started/introduction/).

## Create Docker compose.yml

Create an empty folder and create empty **compose.yml** file inside of it. Next, copy the contents of the following [compose.yml](./compose.yml) file into it. Ensure that both both of them have the same file contents before continuing.

> [!TIP]
> If on Linux, modify the **PUID** with your User ID and **PGID** with your Group ID. Use `id -u` and `id -g` to get your User and Group ID respectivelly.

## Start CloudyMC container

Open the terminal inside the previously created folder and run the following command `docker compose up -d`. It will take some time to download and start for the first time. When finished, you should see a new **data** folder.

To access the web form, open your web browser and type the following URL into th search bar `http://127.0.0.1:8000`. The web form runs on your local network, and should not be exposed to the outside internet (it shouldn't do it by default).

> [!TIP]
> If you cannot access the web interface, you can try to modify its port in the **compose.yml** like this:
>
> ```yaml
> ports:
>   - 8020:8000
> ```
>
> After that, run `docker compose restart` and see if you can access it by using the new port in the URL.

## Generate SSH Keys

SSH keys are used to establish a safe connection with the cloud instance. The **default** key is used for default instance user (e.g. ubuntu) and the user that automatically configures the cloud instance. The **SFTP** key is used for the Secure File Transfer Protocol that enables you to upload, download and modify Minecraft Server Files stored on the instance.

Navigate to the **data/ssh_keys** folder. Open the terminal in this folder and run the following commands:

`ssh-keygen -t ed25519 -f ./mc-default -N ""`

`ssh-keygen -t ed25519 -f ./mc-sftp -N ""`

With that done, you should see 4 files inside the **ssh_keys** folder named **mc-default** and **mc-sftp** and thier counterparts with **.pub** suffix.
