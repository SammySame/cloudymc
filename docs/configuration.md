# Minecraft Server Configuration

## Quick Form Overview

Upon loading the web form, you will be greeted with several fields. Those marked with the asterisk `*` are required to be filled. Most of them have explanations below or sometimes above them.

There are 3 buttons at the bottom of the form named **Submit**, **Test**, **Destroy**. After pressing **Submit** or **Test**, form data is validated and if something is wrong, the appropriate fields will be highlighted. The buttons have tooltip explanations when hovered over with mouse.

At the bottom of the form, you will be able to pick your preferred cloud provider. If you are required to provide additional SSH key for cloud authentication, put the key into **data/ssh_keys** folder and type the file name in the filed.

## Basic Setup

Fill the form with data and press the **Submit** button. You might have to wait for around 5 minutes on the initial configuration. After it finishes, you will be greeted with a dialog box telling you if the operation succeeded.

If successful, you can copy the IP located at the bottom of the web form and use it in the server address field in the game.

> [!NOTE]
> If using custom Minecraft server port (not 25565), remember to add the port after the instance IP. So as an example, you would do 123.123.123.123:54321.

If unsuccessful, press the **Submit** button one more time. You will be warned about potential loss of cloud instance data, but since we just created it and changed nothing, you can safely ignore it by typing in **yes** and continuing.

You should have a working Minecraft server hosted entirely in the cloud!

## Advanced Setup

### Custom Minecraft Server Icon

To provide a custom server icon, open the **data** folder and paste your icon file named **server-icon.png**. Subsequently, press the **Submit** button and wait for it to finish. It will be automatically copied into the appropriate cloud instance folder.

### Custom compose.yml for Minecraft Server on Docker

As the Minecraft server is run with the [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server), you can provide your custom compose file. It allows a much deeper level of customization, compared to using the form. To do so, create a **compose.yml** file in the **data** folder. For information on configuring it, see the documentation for [Minecraft Server on Docker](https://docker-minecraft-server.readthedocs.io/en/latest/).

> [!IMPORTANT]
> There are a few things worth noting:
>
> - All of the settings under the **Minecraft** category in the web form will be ignored (see bellow for exceptions)
> - Server port and any additional ports must also be defined in the web form
> - Volume for Minecraft server data must be defined as **./data:/data**

If a custom compose file is created in the **data** directory, you will get notified about it in the web form (might require page reload).

### Accessing Minecraft Server Files

SFTP is automatically configured in the cloud instance. To access it, either download an FTP software solution or use terminal commands to access it. Generally, for both CLI and GUI FTP software, you will need instance username, IP and SSH key. You have already created the SFTP SSH key in the initial configuration, it can be found under the **data/ssh_keys/\<your-sftp-key-name>**. The instance IP can be found at the bottom of the web form page. The user is named **minecraft-admin**.

I will only be providing CLI commands, as FTP software can vary vastly. Open your terminal in the **data/ssh_keys** folder and type the following command `sftp -i mc-sftp minecraft-admin@\<my-instance-ip>`. The Minecraft server files are stored under the **minecraft-server** bind mount folder.
