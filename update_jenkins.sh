#!/bin/bash
#
#       _            _    _             _    _           _       _            
#      | |          | |  (_)           | |  | |         | |     | |           
#      | | ___ _ __ | | ___ _ __  ___  | |  | |_ __   __| | __ _| |_ ___ _ __ 
#  _   | |/ _ \ '_ \| |/ / | '_ \/ __| | |  | | '_ \ / _` |/ _` | __/ _ \ '__|
# | |__| |  __/ | | |   <| | | | \__ \ | |__| | |_) | (_| | (_| | ||  __/ |   
#  \____/ \___|_| |_|_|\_\_|_| |_|___/  \____/| .__/ \__,_|\__,_|\__\___|_|   
#                                             | |                             
#                                             |_|                             
# Author: Triopsi
# Date: 27-01-2021
# info@triopsi.com
# Autoupdater for jenkins
# Usage: 
# 1) Edit the jenkins auth variable
# 2) chmod +x updater_jenkins.sh
# 3) ./updater_jenkins.sh 
# For daily checks (every night at 1am)
# crontab -e
# 0 1 * * * /bin/bash -c "path/to/update_jenkins.sh" >> /var/log/updateJenkins.log 2>&1



#Jenkins instance variable
jenkins_url="http://localhost:8080/"
auth_username="" #Jenkins Username
auth_api="" # Jenkins API token; Username -> Settings -> API Token

######################################   MAIN  ###############################

function logInfo
{
  local ts
  ts="$(date +'%Y%m%d-%H%M%S%z')"
  echo "${ts} INFO $*"
}
function logErr
{
  local ts
  ts="$(date +'%Y%m%d-%H%M%S%z')"
  echo "${ts} ERROR $*"
  echo "${ts} ERROR $*" >&2
}

function wait_bar
{
 	local max_time=$1
	echo "max time=$max_time"
	for i in {1..120}
  	do
    		printf '= %.0s' {1..$i}
    		sleep 1
  	done
  	echo
}

logInfo "Jenkins Auto Update v1.0"

#get the actual version
actual_jenkins_version=`java -jar jenkins-cli.jar -s $jenkins_url -auth $auth_username:$auth_api version | xargs`
new_version=`curl --silent https://updates.jenkins.io/current/latestCore.txt | xargs`

logInfo "Aktuelle installierte Version: $actual_jenkins_version"
logInfo "Neuste Jenkins Version: $new_version"


if [ "$actual_jenkins_version" != "$new_version"  ];then

	# move in folder
	cd /usr/share/jenkins

	logInfo "Stoppe jenkins"
	systemctl stop jenkins
	if [ $? -ne 0 ];then
		logErr "Konnte nicht heruntergefahren werden..."
		exit 99
	else
		logInfo "Done"
	fi

	logInfo "Backup alte WAR File"
	mv jenkins.war jenkins.war.$actual_jenkins_version

	logInfo "Download letzte Jenkins Version"
	wget -q https://updates.jenkins-ci.org/latest/jenkins.war
	if [ $? -ne 0 ];then
		logErr "Konnte nicht die letzte version von Jenkins downlaoden..."
		exit 99
	else
		logInfo "Done"
	fi

	logInfo "Start Jenkins...."
	systemctl start jenkins
	if [ $? -ne 0 ];then
		logErr "Kontne Jenkins nicht wieder neu starten..."
		exit 99
	else
		logInfo "Done"
	fi

	cd -
	#Warten auf wiederauferstehung
	wait_bar

	#Hole Version
    new_jenkins_version=""
    i=1

    logInfo "Pruefe auf erreichbarkeit"
    while [ -z "${new_jenkins_version}" ];do
        logInfo "Versuch: $i"
        new_jenkins_version=$( java -jar jenkins-cli.jar -s $jenkins_url -auth $auth_username:$auth_api version );
        if [ -z "$new_jenkins_version" ];then
            logInfo "Jenkins ist noch nicht erreichbar. Warte 20s fuer den naechsten Versuch."
            sleep 20
        fi
        i=$(($i+1))
    done

    UPDATE_LIST=$( java -jar jenkins-cli.jar -s $jenkins_url -auth $auth_username:$auth_api list-plugins | grep -e ')$' | awk '{ print $1 }' );
    if [ ! -z "${UPDATE_LIST}" ];then
            logInfo Updating Jenkins Plugins: ${UPDATE_LIST};
            java -jar jenkins-cli.jar -s $jenkins_url -auth $auth_username:$auth_api install-plugin ${UPDATE_LIST};
            java -jar jenkins-cli.jar -s $jenkins_url -auth $auth_username:$auth_api safe-restart;
    fi
	logInfo "Neue Version: $new_jenkins_version"
	logInfo "Jenkins wurde erfolgreich upgedatet. :)"

else
	logInfo "Jenkins ist schon aktuell. Keine Aktion nötig :)"
fi
