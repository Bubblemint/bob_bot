debug_flag=0
while getopts "D" option
do
    case $option in
        D)
            debug_flag=1
            ;;
        \?)
            echo "Usage: get_menu.sh [-D]" 1>&2
            exit 1
            ;;
    esac
done

NOW=$(date +%H)
if [ "$NOW" -lt 13 ]; then 
	MENU="Lunch"
else
	MENU="Dinner"
fi

NOIMAGE="http://tv01.search.naver.net/ugc?q=http://img.phinf.pholar.net/20160124_43/1453561736142MzFi0_JPEG/pholar_20160124000854.jpg"

TODAY=$(date +%Y%m%d) 
NAMES=$(cat /BOB/data/$TODAY | grep "var "$MENU"ListJson" | awk '{print substr($0,index($0,$4))}' | sed 's/\;//g' | /usr/local/bin/jq ".[]|.CfMenu_Food" | uniq |  sed 's/\"//g')

i=0
IMAGES=()
for NAME in $NAMES; do

NAME=$(python -c "import urllib, sys; print urllib.quote('"$NAME"')")
IMAGES[$i]=$(curl "https://openapi.naver.com/v1/search/image.json?display=1&start=1&query=$NAME&sort=sim" -H "X-Naver-Client-Id: Fq7SyLy3J2Gmih2xpkmw" -H "X-Naver-Client-Secret: oLMKw4A2SA" | /usr/local/bin/jq ".items[]|.thumbnail"|  sed 's/\"//g')

let i=i+1
done

DATA=$(cat /BOB/data/$TODAY | grep "var "$MENU"ListJson" | awk '{print substr($0,index($0,$4))}' | sed 's/\;//g' | /usr/local/bin/jq "[.[]| {index:.CfMenu_Name,title: .CfMenu_Food, text: [.MenuFoodList| .[] | .CfFood_Name]}]" |sed -e '/\"\",/d'| /usr/local/bin/jq 'unique'| /usr/local/bin/jq ". | map(.image_url = if (.index) == "'"'"B"'"'" then "'"'"${IMAGES[1]:-$NOIMAGE}"'"'" else "'"'"${IMAGES[0]:-$NOIMAGE}"'"'" end)" | tr '\n' ' ' | sed 's/",       "/\\n/g' | sed 's/\[//g' | sed 's/\]//g')


if [ $debug_flag -eq 1 ]; then
    echo "[ $DATA ]"| tr '\n' ' '|/usr/local/bin/jq . 
else

#curl -X POST -H 'Content-type: application/json' --data '{"attachments": [ '"$DATA"' ], "username": "sdp-BOB-bot", "icon_emoji": ":fork_and_knife:"}' https://hooks.slack.com/services/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
#curl -X POST -H 'Content-type: application/json' --data '{"attachments": [ '"$DATA"' ], "channel": "#jr", "username": "jr-BOB-bot", "icon_emoji": ":fork_and_knife:"}' https://hooks.slack.com/services/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
curl -X POST -H 'Content-type: application/json' --data '{"attachments": [ '"$DATA"' ], "channel": "#bob", "username": "modeling-BOB-bot", "icon_emoji": ":fork_and_knife:"}' https://hooks.slack.com/services/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
fi
