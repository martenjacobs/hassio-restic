# HassOS restic add-on

This add-on runs [restic](https://restic.net/) to make efficient back-ups from your HassOS installation. You can use this instead of or together with HassOSs built-in snapshot functionality. In my case, I use it because the built-in snapshot functionality doesn't really like backing up my influxdb database, which is more than 5 GiB. 

# What is it
You can read more about restic on [restic.net](https://restic.net/), but what is basically does is create differential back-ups to a targets of your preference, like S3 compatible storage, REST, files, SFTP or anything supported by rclone. This means you can run backups daily without generating an enormous file every day. 

This add-on mounts the hassos data partition and runs the `restic backup` command in it. Configuration is done through [environment variables](https://restic.readthedocs.io/en/stable/040_backup.html#environment-variables), and you can supply a list of files to exclude from the back-up. To automatically create back-ups you can create an automation in Home Assistant that starts this add-on periodically.

# Protection mode

To use this add-on, it's required to switch off "Protection mode".

> A red warning message will appear on the top. This is expected, because the add-on needs full filesystem access to be able to create a back-up. I'd prefer that the add-on would only have read-only access to the file system, but as of yet I don't think that's possible with HassOS (if I'm wrong, please open an issue on [Github](https://github.com/martenjacobs/hassio-restic/issues) and tell me how). 
> If you don't trust this add-on to have full filesystem access, I'm afraid the only option at the moment is not to use it.

# Basic set-up
This add-on requires a restic repository to be already set up. You can do this by using the `restic init` command from another system (more info can be found [here](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html)). When creating your repository, you'll be asked to supply a password. Make sure to safely store that password somewhere, because losing it will make it impossible to recover from the back-up if your HassOS install crashes.

After this you can configure the add-on using the environment variables listed [here](https://restic.readthedocs.io/en/stable/040_backup.html#environment-variables). Which specific variables you need to supply depends on your set-up, but there's an example below on how to set it up using MinIO, which is a self-hosted S3 compatible storage server. In the configuration tab of the add-on you can list all the environment variables you need to be set under the `env_vars` key.

## MinIO Example
Personally, I use restic to back-up to my file server which is running MinIO under Docker. MinIO is an open source S3 compatible storage server that you can host yourself. If you don't have MinIO yet, you can find some info on how to set it up on [Docker Hub](https://hub.docker.com/r/minio/minio/). 
Because MinIO is S3 compatible, the configuration of restic will be very similar to the set-up for AWS S3, Wasabi, or any other S3-compabible storage provider.

### Create bucket
Once you have MinIO up and running, you should create a bucket called "restic-backups". You can do this using MinIO's web interface. This bucket can be shared among multiple restic repositories, because we'll place those under a prefix.

### Create user
For added security, I like to create separate users for all my back-up clients. To do this, we'll use the [MinIO Client](https://docs.min.io/docs/minio-client-complete-guide.html) (`mc`). You can install it on your local system or run it in Docker (there's an image called `minio/mc` which is the one I use). 

You should create an alias to your MinIO installation with the admin credentials which you can use later to create users. 

I created a script that will create a user and gives it access to only the prefix required for the back-up:
```bash
$ wget https://github.com/martenjacobs/hassio-restic/raw/master/scripts/add-minio-user.sh
$ sh add-minio-user.sh
Back-up repository name: my-server
Client password: my-long-random-password
MinIO alias: my-minio
Will create a user called "my-server-restic" with password "my-long-random-password" on minio instance "my-minio". Continue? (y/n) y

Creating user
Creating policy
Attaching policy
Done


Use these environment variables:
AWS_ACCESS_KEY_ID: 'my-server-restic'
AWS_SECRET_ACCESS_KEY: 'my-long-random-password'
RESTIC_REPOSITORY: 's3:<minio server address>/restic-backups/my-server'
```

### Create restic repository
Now you can use these environment variables to create a restic repository. First make sure you have restic installed (you can use Docker or a local install) and run:
```bash
$ export AWS_ACCESS_KEY_ID='my-server-restic'
$ export AWS_SECRET_ACCESS_KEY='my-long-random-password'
$ export RESTIC_REPOSITORY='s3:<minio server address>/restic-backups/my-server'
$ restic init
```

This will ask you for a repository password. Use a (different) long random password. Make sure you write this one down somewhere, because losing it will make it impossible to recover from the back-up. For this example, I'll use `my-long-different-password`.
After restic has created the repository, which shouldn't take more than a few seconds, you can configure the add-on.

### Configure add-on
In the configuration tab of the add-on, you can add the following configuration:
```yaml
env_vars:
  AWS_ACCESS_KEY_ID: 'my-server-restic'
  AWS_SECRET_ACCESS_KEY: 'my-long-random-password'
  RESTIC_REPOSITORY: 's3:<minio server address>/restic-backups/my-server'
  RESTIC_PASSWORD: 'my-long-different-password'
exclude_patterns:
  - homeassistant/home-assistant.log
  - homeassistant/home-assistant_v2.db
  - addons/data/a0d7b954_influxdb/influxdb/wal
  - addons/data/52a4f95e_restic/restic-cache
```

The default exclude patterns are a starting point. You may want to add some more depending on your set-up and which add-ons you have installed. The patterns should be in the format understood by restic's `--exclude` format, which is documented [here](https://restic.readthedocs.io/en/stable/040_backup.html#excluding-files).

When you're done, click "Save".

### Running the add-on

You can now click "Start" on the add-on Info tab. This will start a back-up. You can see what happens in the Log tab. If everything goes well, you should see a line somewhere near the bottom like:
```
snapshot f1065f02 saved
```
This means the snapshot was created successfully. The add-on stops after it's done creating a back-up.

### Automatic back-ups

This add-on doesn't run automatically at certain times, but you can easily automate that. To create a new back-up, you can call the `hassio.addon_start` service with the following service data: `addon: '52a4f95e_restic'`.
You can set up an automation in Home Assistant to trigger this periodically, or use NodeRED or AppDaemon, whichever is your preference.

# Still to do (no ETA)
There are a few things that could be improved in this add-on, but I have no idea when (if ever) I'll get around to doing it:
- There's no back-up thinning yet, meaning the repository will steadily become bigger if not manually cleaned up every once in a while.
- There's no quoting around the environment variables, which could cause issues with some special characters I think
- There's no scheme defined for the configuration.
- It would be nice if the add-on would be able to create a repository by itself.
- AFAICT it's not possible for a HassOS add-on to mount the data partition as read-only and there's no other way to get access to data from other add-ons. This means the add-on has full rw access on all add-on files, which is not necessarily what you want.
