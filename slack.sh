#!/bin/bash

# Slack incoming web-hook URL and user name
url='CHANGEME'		# example: https://hooks.slack.com/services/QW3R7Y/D34DC0D3/BCADFGabcDEF123
username='Zabbix'	# should match the one set in Slack's Webhook configuration page

## Values received by this script:
# To = $1 (Slack channel or user to send the message to, specified in the Zabbix web interface; "@username" or "#channel")
# Subject = $2 (usually either PROBLEM or RESOLVED)
# Message = $3 (whatever message the Zabbix action sends, preferably something like "Zabbix server is unreachable for 5 minutes - Zabbix server (127.0.0.1)")

# Get the Slack channel or user ($1) and Zabbix subject ($2)
to="$1"
subject="$2"

# Change message emoji depending on the subject - smile (RECOVERY), frowning (PROBLEM), or ghost (for everything else)
# NOTE: Multiple sequential messages get the same emoji in Slack, so we'd rather use a color (within an attachment)
#  See https://api.slack.com/docs/attachments for further details
if [[ "$subject" =~ "RESOLVED" ]]; then
        emoji=':smile:'
        color='good'	# Might also be a color name or hex code
elif [[ "$subject" =~ "PROBLEM" ]]; then
        emoji=':frowning:'
        color='danger'
else
        emoji=':ghost:'
        color='warning'
fi

# The message (in form of attachment) that we want to send to Slack is the "subject" value
#  followed by the message that Zabbix actually sent us ($3)
message="$3"

# We might also want to put a link to the Zabbix Console
zabbix_url="https://ZABBIX_HOST:PORT/zabbix"
link="$zabbix_url/tr_status.php"

# The title of the message will be the subject with the link (i.e. <a href="link">RESOLVED</a> Trigger)
title="<$link|${subject}> Trigger"

# Let's build the attachment (see attached picture to see the result)
attachments=`cat <<EOF
[
{
"fallback": "$title: $message",
"title": "$title",
"text": "$message",
"color": "$color"
}
]
EOF
`

# We might also want to log the message sent
echo "`date -u` - Sending Slack alert to=$to, subject=$subject, status=$color" >> /var/log/zabbix/slack.log

# Build our JSON payload and send it as a POST request to the Slack incoming web-hook URL
payload="payload={\"channel\": \"${to}\", \"username\": \"${username}\", \"attachments\": ${attachments}}"
curl -m 5 --data-urlencode "${payload}" $url