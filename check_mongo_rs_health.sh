replica_set=$1
replica_set_members=$2
username=$3
password=$4
ssl_ca_file=$5
ssl_pem_file=$6
server_name=$7

. ./config/config.sh

get_rs_health(){
    mongo --eval "JSON.stringify(db.adminCommand({ replSetGetStatus: 1 }))" --username $username --password $password --authenticationDatabase admin --quiet --ssl --sslCAFile $ssl_ca_file --sslPEMKeyFile $ssl_pem_file --host $replica_set/$replica_set_members | sed '/^2020/ d' > ./logs/data_$replica_set.json
}

check_connection(){
    mongo --eval "db.logout()" --username $username --password $password --authenticationDatabase admin --ssl --sslCAFile $ssl_ca_file --sslPEMKeyFile $ssl_pem_file --host $replica_set/$replica_set_members > ./logs/mongo_connection_$replica_set.log
}

get_member(){
    cat $1 | jq -r "$2"
}

send_slack_message(){
    data='{
        "blocks": [
            {
                "type": "divider"
            }
        ],
        "attachments": [
            {
                "fallback": "Required plain-text summary of the attachment.",
                "color": "#ff0000",
                "pretext": "'$1'",
                "title": "",
                "title_link": "https://api.slack.com/",
                "text": "'$2'",
                "fields": [
                    {
                        "title": "Priority",
                        "value": "High",
                        "short": false
                    }
                ],
                "footer": "tribeOS",
                "footer_icon": "https://pbs.twimg.com/profile_images/1069685879432757252/ThmhhBei.jpg",
                "ts": "'$3'"
            }
        ]
    }'
    
    curl -X POST -H 'Content-type: application/json' --data "$data" $SLACK_API_URL
}

if check_connection; then
    get_rs_health
    
    fetch_date=$(date +"%s")
    
    for x in $(seq 1 $(get_member /data_$replica_set.json '.members | length'))
    do
        replica_set_member=$(get_member ./logs/data_$replica_set.json .members[$x-1].name)
        lastHeartbeatMessage=$(get_member ./logs/data_$replica_set.json .members[$x-1].lastHeartbeatMessage)
        replica_set_health=$(get_member ./logs/data_$replica_set.json .members[$x-1].health)
        replica_set_state=$(get_member ./logs/data_$replica_set.json .members[$x-1].stateStr)
        
        if [ "$replica_set_state" != "PRIMARY" ] && [ "$replica_set_state" != "SECONDARY" ]; then
            send_slack_message "There are errors in $replica_set_member. Replica set state is $replica_set_state"
        fi
        
        if [ "$replica_set_health" = "1" ]; then
            echo "All OK for "$replica_set_member
        else
            if [ "$lastHeartbeatMessage" != "" ]; then
                send_slack_message "There are errors in $replica_set_member." "$lastHeartbeatMessage" $fetch_date
            elif [ "$infoMessage" != "" ]; then
                send_slack_message "There are errors in $replica_set_member." "$infoMessage" $fetch_date
            fi
        fi
    done
else
    send_slack_message "Connection to the *$replica_set* could not be established. Please check what is happening." "Error log available at http://$server_name/mongo/logs/mongo_connection_$replica_set.log" $fetch_date
fi