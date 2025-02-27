# Healing_KC

----------------------------------------------

# **Descriptsion**
 
The aim from the script is : to monitor an host heart-beat, and in case of the host become unreachable the script will run another script "in this case called service script"
to take and action

beside that the responses will be saved in a Json file.

the criteria of the script is, if the host is unreachable and there are less than 3 process ID running "with specific name" the script will call the second script to take an action.

And this condition because in my case I have more than 2 versions running simultaneously from this application.

# to run with Cron 

run ` $ Crontab -e `

# Running the Script every 2 minutes.
` */2 * * * * /bin/sh -c  /ln/healing_4_1.sh >> /ln/$(date '+\%Y-\%m-\%d')_healing_script.log 2>&1 `

# Stop monitoring script at end of day for daily restart
` 59 23 * * * /usr/bin/kill $(ps -ef|grep healing|grep keycloak|grep -v grep|awk {'print $2'}) > /dev/null 2>&1` 

to run >> ' $ bash ./healing_script_sync_json '
to run in the background >>   `nohup ./healing_script_sync_json >/dev/null 2>&1 &`
in case of you got permission denied run `chmod +x ./healing_script_sync_json`

the responses reads in case the host not available >> KeyCloak not reachable in this case 

![image](https://github.com/user-attachments/assets/0221fed1-958b-4526-aedd-e96170c28cb4)


