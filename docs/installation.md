# CloudyMC Installation Guide

> [!WARNING]
> I am not accountable for any unexpected charges from cloud providers or potential server data loss. This is a solo person project that is quite difficult to test properly. I have put in place some countermeasures (like Oracle Cloud free tier validation in Terraform) that should hopefully disallow that from happening. I am unable to predict whether cloud providers will begin charging differently for something. Just keep that in mind before continuing :D.

## Install Docker and Docker Compose

Follow the official Docker documentation for your specific operating system for either [Docker Desktop](https://docs.docker.com/desktop/) or [Docker](https://docs.docker.com/engine/install/). If you are unfamiliar with Docker, install Docker Desktop, as it offers a graphical user interface and is easier to install. If you installed Docker Desktop, then you already have Docker Compose, if you didn't, then follow the official [Docker Compose installation](https://docs.docker.com/compose/install/#install-compose) page.

## Create Docker compose.yml

Create an empty folder and create a file named **compose.yml** and a folder named **data**. The file structure should look something like this:
```
cloudymc/
├── compose.yml
└── data
```
 Next, copy the contents of the following [compose.yml](./compose.yml) file into the one you just created.

> [!TIP]
> If on Linux, modify the **PUID** with your User ID and **PGID** with your Group ID. Use `id -u` and `id -g` to get your User and Group ID respectivelly.

## Start CloudyMC container

Open the terminal inside the folder that holds the **compose.yml** file and run the following command `docker compose up -d`. It will download and start a container for CloudyMC. After a few moments (internet speed dependent) you should see several files created inside the **data** folder. *You shouldn't* be modifying text files under this folder.

To access the web form, open your web browser and type the following URL into the search bar `http://127.0.0.1:8000`. The web form runs on your local network, and shouldn't be exposed to the outside internet.

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

With that done, you should see 4 files inside the **ssh_keys** folder named **mc-default** and **mc-sftp** and their counterparts with **.pub** suffix.

## Web Form Configuration

Take the time to carefully fill out the form with necessary data. Most of the fields have explanations attached to them. When ready, press the **Submit** button and patiently wait for the webpage to show a message box indicating failure or success.

> [!TIP]
> You can open the web console (**F12** key on most browsers) to see details about processes that create and configure your cloud instace. Keep in mind that it might include cloud credentials and other sensitive information, so it shouldn't be shared online.

If successful, you can copy the IP located at the bottom of the web form and use it in the server address field in the game.

> [!NOTE]
> If using custom Minecraft server port (not 25565), remember to add the port after the instance IP. So as an example, you would do 123.123.123.123:54321.

If unsuccessful, press the **Submit** button a second time. You will be warned about potential loss of data, but since we just created it and changed nothing, you can safely ignore it by typing in **yes** and continuing.

## Removing Everything

Doing this will erase all cloud resources created by CloudyMC. Any data stored on this instance will be lost. To accomplish it, just enter the web form, scroll to the bottom of the page and press the **Destroy** button. You will be informed on when the task is finished.

# Roll the credits

Once you followed this guide up to this point, you should have a working Minecraft server that you and others can join. There are other things worth considering, depending on the type of server. For a long-term one, some kind of backups will be a good idea (automatic backups are planned for future release). If you want to dive deeper into server configuration, including a modded server, refer to this [advanced configuration](./advanced) guide.
