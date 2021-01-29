# Jenkins-Updater basj script
Simple bash script to update a Jenkins instance + update jenkins plugins.

On the jenkins server create or copy the `update_jenkins.sh` file. Open the file and change the auth variable.

e.g.
```
cd /tmp
git clone https://github.com/triopsi/backup_jenkins.git
sudo chmod +x update_jenkins.sh
sudo nano update_jenkins.sh
sudo ./update_jenkins.sh
```

For daily checks (every night at 1am)
```
crontab -e
0 1 * * * /bin/bash -c "path/to/update_jenkins.sh" >> /var/log/updateJenkins.log 2>&1
```

# Install jenkins-cli

```
curl -L https://github.com/jenkins-zh/jenkins-cli/releases/latest/download/jcli-linux-amd64.tar.gz|tar xzv
sudo mv jcli /usr/local/bin/
```

