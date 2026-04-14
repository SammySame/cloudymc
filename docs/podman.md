# Install as Rootless Podman Quadlet

This is a more advanced setup, you should only do it if you are already familliar with Podman Quadlets.

The following pre-made Quadlet configuration [podman.container](./podman.container) file can be used. It is hardened by using only the required Linux capabilities, NoNewPriviliges seccomp set to true, and limited amount of assigned RAM memory. This file should be placed in the `/home/<your-user-name>/.config/containers/systemd/` folder and renamed to something memorable, like cloudymc.container.

You might also be required to change the **UserNS** ids to match the running user UID and GID. Avoid using the **PUID** and **PGID** environment variables, as this is already handled by this setting.
