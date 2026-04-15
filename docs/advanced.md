# Advanced Configuration

### Custom Minecraft Server Icon

To provide a custom server icon, open the **data** folder and paste your icon file named **server-icon.png**. Next, press the **Submit** button and wait for it to finish. It will be automatically copied into the server folder in the cloud.

### Custom compose.yml for Minecraft Server on Docker

As the Minecraft server is run with the [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server), you can provide your custom compose file. It allows a much deeper level of customization, compared to using the form. To do so, create a **compose.yml** file in the **data** folder. For information on configuring it, see the documentation for [Minecraft Server on Docker](https://docker-minecraft-server.readthedocs.io/en/latest/).

> [!IMPORTANT]
> There are a few things worth noting:
> - This compose file is different from the one that starts CloudyMC. It's used for starting a container on the cloud intance
> - All of the settings under the **Minecraft** category in the web form will be ignored in favor of your configuration (see bellow for exceptions)
> - Server port and any additional ports must also be defined in the web form
> - Volume for Minecraft server data must be defined as **./data:/data**

If a custom compose file is created in the **data** directory, you will get notified about it in the web form (might require page reload).

### Accessing Minecraft Server Files

SFTP is automatically configured in the cloud instance. To access it, either download an FTP software solution or use terminal commands to access it. Generally, for both CLI and GUI FTP software, you will need instance username, IP and SSH key. You have already created the SFTP SSH key in the initial configuration, it can be found under the **data/ssh_keys/\<your-sftp-key-name>**. The instance IP can be found at the bottom of the web form page. The user is named **minecraft-admin**.

The following example is for CLI (terminal) only. Consult the documentation for your specific software for details. Open the terminal in the **data/ssh_keys** folder and run the following command `sftp -i mc-sftp minecraft-admin@\<my-instance-ip>`. 

If successful, you should be able to use Linux commands to manipulate the remote file system. The Minecraft server files are stored under the **minecraft-server** bind mount folder.
