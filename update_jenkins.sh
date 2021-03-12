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
# Date: 12-03-2021
# info@triopsi.com
# Autoupdater for a jenkins
# Usage: 
# 1) Edit the jenkins auth variable
# 2) chmod +x updater.sh
# 3) ./updater.sh 

#Jenkins instance variable
jenkins_url="http://localhost:8080/"
auth_username="" # Username
auth_api="" # AUTH token

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
	sleep 120
}

logInfo "Start Check Autoupdate...."

#get the actual version
actual_jenkins_version=`java -jar jenkins-cli.jar -s $jenkins_url -auth $auth_username:$auth_api version | xargs`
new_version=`curl --silent https://updates.jenkins.io/current/latestCore.txt | xargs`

logInfo "Actual installed version: $actual_jenkins_version"
logInfo "Newest jenkins version: $new_version"

if [ "$actual_jenkins_version" != "$new_version"  ];then

	logInfo "Start update..."

	# move in folder
	cd /usr/share/jenkins

	logInfo "Stop jenkins"
	systemctl stop jenkins
	if [ $? -ne 0 ];then
		logErr "Konnte nicht heruntergefahren werden..."
		exit 99
	else
		logInfo "Done"
	fi

	logInfo "Backup old WAR file"
	mv jenkins.war jenkins.war.$actual_jenkins_version

	logInfo "Download last jenkins version"
	wget -q https://updates.jenkins-ci.org/latest/jenkins.war
	if [ $? -ne 0 ];then
		logErr "Konnte nicht die letzte version von Jenkins downlaoden..."
		exit 99
	else
		logInfo "Done"
	fi

	logInfo "Start jenkins"
	systemctl start jenkins
	if [ $? -ne 0 ];then
		logErr "Kontne Jenkins nicht wieder neu starten..."
		exit 99
	else
		logInfo "Done"
	fi

	cd -

	#Warten auf wiederauferstehung
	logInfo "Wait 120sek..."	
	wait_bar

	#Hole Version
	new_jenkins_version=""
	i=1

	logInfo "Check for availability..."
	while [ -z "${new_jenkins_version}" ];do
		logInfo "Round: $i"
		new_jenkins_version=$( java -jar jenkins-cli.jar -s $jenkins_url -auth $auth_username:$auth_api version );
		if [ -z "$new_jenkins_version" ];then
			logInfo "Jenkins ist noch nicht erreichbar. Warte 20s fuer den naechsten Versuch."
			sleep 20
		fi
		i=$(($i+1))
	done

	logInfo "Jenkins are online"
	logInfo "Check plugins version"
	UPDATE_LIST=$( java -jar jenkins-cli.jar -s $jenkins_url -auth $auth_username:$auth_api list-plugins | grep -e ')$' | awk '{ print $1 }' ); 
	if [ ! -z "${UPDATE_LIST}" ];then 
   		logInfo Updating Jenkins Plugins: ${UPDATE_LIST}; 
 		java -jar jenkins-cli.jar -s $jenkins_url -auth $auth_username:$auth_api install-plugin ${UPDATE_LIST};
   		java -jar jenkins-cli.jar -s $jenkins_url -auth $auth_username:$auth_api safe-restart;
	fi

	logInfo "Your new jenkins version: $new_jenkins_version"
	logInfo "Jenkins update done :)"

else
	logInfo "Jenkins are up to date. Nothing to do. Bye :)"
fi
echo
exit 0
