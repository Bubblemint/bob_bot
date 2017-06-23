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

NOIMAGE="http://tv01.search.naver.net/ugc?q=http://img.phinf.pholar.net/20160124_43/1453561736142MzFi0_JPEG/pholar_20160124000854.jpg"

TODAY=$(date +%Y%m%d) 
NAMES=$(cat /BOB/data/$TODAY | grep "var LunchListJson" | awk '{print substr($0,index($0,$4))}' | sed 's/\;//g' | /usr/local/bin/jq ".[]|.CfMenu_Food" | uniq |  sed 's/\"//g')

i=0
IMAGES=()
for NAME in $NAMES; do
     IMAGES[$i]=$(curl http://openapi.naver.com/search\?key\=Fq7SyLy3J2Gmih2xpkmw\&target\=image\&query\=$NAME | grep -oE "<thumbnail>[^<]+</thumbnail>" | sed 's/<[\/]*thumbnail>//g'| head -n 1)  
let i=i+1
done

DATA=$(cat /BOB/data/$TODAY | grep "var LunchListJson" | awk '{print substr($0,index($0,$4))}' | sed 's/\;//g' | /usr/local/bin/jq "[.[]| {index:.CfMenu_Name,title: .CfMenu_Food, text: [.MenuFoodList| .[] | .CfFood_Name]}]" |sed -e '/\"\",/d'| /usr/local/bin/jq 'unique'| /usr/local/bin/jq ". | map(.image_url = if (.index) == "'"'"B"'"'" then "'"'"${IMAGES[1]:-$NOIMAGE}"'"'" else "'"'"${IMAGES[0]:-$NOIMAGE}"'"'" end)" | tr '\n' ' ' | sed 's/",       "/\\n/g' | sed 's/\[//g' | sed 's/\]//g')

if [ $debug_flag -eq 1 ]; then
    echo "[ $DATA ]"| tr '\n' ' '|/usr/local/bin/jq .
else
    curl -X POST -H 'Content-type: application/json' --data '{"attachments": [ '"$DATA"' ], "channel": "#test-jkang", "username": "monkey-bot", "icon_emoji": ":monkey_face:"}' https://hooks.slack.com/services/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
fi 
