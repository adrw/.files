# Synology

# Syncthing

- In Control Panel -> Group -> sc-syncthing, add R/W permissions for all folders that will be synced
- In Control Panel -> Shared Folder -> each folder that will be synced, go to Permissions -> System Internal User -> sc-syncthing and add R/W permissions
- In File Station -> each folder that will be synced, in sidebar right click on folder root -> Permissions and check the box "Apply to all enclosed folders and files".

# Setup Notes

## Commands

- Force change password of root or synology user: `sudo synouser --setpw {username} {passwd}`

## Configuring SSH with Keys

Source: [chainsaw on a tire swing 1](https://www.chainsawonatireswing.com/2012/01/15/ssh-into-your-synology-diskstation-with-ssh-keys/), [chainsaw on a tire swing 2](https://www.chainsawonatireswing.com/2012/01/16/log-in-to-a-synology-diskstation-using-ssh-keys-as-a-user-other-than-root/)

Login with root

To start the process, you need to edit the SSH daemon’s config file to allow access via keys. Edit /etc/ssh/sshd_config using vim & change these lines:

```
#RSAAuthentication yes
#PubkeyAuthentication yes
#AuthorizedKeysFile .ssh/authorized_keys
```

To this:

```
#RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
```

Save the file.

Time to create the necessary .ssh directory & file on your Synology DiskStation:

```
> cd /root
> mkdir .ssh
> touch .ssh/authorized_keys
```

Now get your permissions set correctly on that directory & file:

```
> chmod 700 .ssh
> chmod 644 .ssh/authorized_keys
```

## Now to allow other users to ssh...

The Synology DiskStation has a built-in ability to create home folders for every user—it’s just a bit hidden.

Go to Control Panel > User > User Home. Check the box next to Enable User Home Service & choose a volume that you want your users’ home directories to reside. That’s the simple part. Now if you log in as admin, you’ll see that you have your own home directory:

```
$  ssh admin@IP
admin@IPs password:

BusyBox v1.16.1 (2011-11-26 14:58:46 CST) built-in shell (ash)
Enter 'help' for a list of built-in commands.

> pwd
/volume1/homes/admin
```

Yup, that worked. But what about .ssh? Easy. Log in as root, & just copy the .ssh folder from root’s home to admin’s home:

```
$ ssh root@IP
> cp -R .ssh /volume1/homes/admin
> ls -l /volume1/homes/admin/
drwx------2 root root  4096 Jan 15 13:11 .ssh
```

We’re not done, though. Notice that admin’s .ssh is owned by root, which isn’t gonna work when admin tries to log in. So, while still logged in as root, we need to change ownership of that directory & its contents:

```
> chown -R admin:users .ssh
> ls -l
drwx------2 adminusers 4096 Jan 15 13:11 .ssh
```

You may also need to do the following:

This will not work if the users home directory is writeable by anyone else.
If you get Permission denied (publickey) you should check directories permission and ownership

```
chown -R <user> /volume1/homes/<user>
chmod 750 /volume1/homes/<user>
chmod 700 /volume1/homes/<user>/.ssh
chmod 600 /volume1/homes/<user>/.ssh/authorized_keys
```

## Ensuring root cannot ssh Login

Source: [mediatemple](https://mediatemple.net/community/products/dv/204643810/how-do-i-disable-ssh-login-for-the-root-user)

Add the user. In the following example, we will use the user name admin. The command adduser will automatically create the user, initial group, and home directory.

```
[root@root ~]# adduser admin
[root@root ~]# id admin
uid=10018(admin) gid=10018(admin) groups=10018(admin)
[root@root ~]# ls -lad /home/admin/
drwx------ 2 admin admin 4096 Jun 25 16:01 /home/admin/
```

Set the password for the admin user. When prompted, type and then retype the password.

```
[root@root ~]# passwd admin
Changing password for user admin.
New UNIX password:
Retype new UNIX password:
passwd: all authentication tokens updated successfully.
[root@root ~]#
```

For sudo permissions for your new admin user, use the following command.

```
[root@root ~]# echo 'admin ALL=(ALL) ALL' >> /etc/sudoers
```

SSH to the server with the new admin user and ensure that the login works.

```
[root@root ~]# ssh admin@my.ip.or.hostname
admin@my.ip.or.hostname's password:
[admin@admin ~]$
```

Verify that you can su (switch user) to root with the admin user.

```
[admin@admin ~]$ su -
Password:
[root@root ~]$ whoami
root
```

To disable root SSH login, edit /etc/ssh/sshd_config with your favorite text editor.

```
[root@root ~]# vi /etc/ssh/sshd_config
```

Change this line:

```
#PermitRootLogin yes
```

Edit to this:

```
PermitRootLogin no
```

Ensure that you are logged into the box with another shell before restarting sshd to avoid locking yourself out of the server.

```
[root@root ~]# /etc/init.d/sshd restart
Stopping sshd: [ OK ]
Starting sshd: [ OK ]
[root@root ~]#
```
