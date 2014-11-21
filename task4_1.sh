#!/bin/bash

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

function show_help {
   cat << EOF
Usage: task4_1 [OPTION]... [FILE]...
Count success request, average request time, 95% quantile request time,
 99% quantile request time for url in time range

  -u    url
  -f    time from in formats HH, HH:MM, HH:MM:SS
  -t    time to in formats HH, HH:MM, HH:MM:SS
  -h    display this help and exit
  -v    output version information and exit

Examples:
  task4_1.sh -f 12 -t 13 -u /user log.txt
  Output stats for url user in time range from 12 to 13

Report task4_1 bugs to overmes@gmail.com
EOF
}
function date_to_int {
    DATEINT=`date -d "1970-01-01 $1" +%s`
}
function read_date_time_level_type_length_url_status_response_from_p {
    IFS=' ' read -a array <<< "$p"
    date=${array[0]}
    time=${array[1]}
    level=${array[2]}
    type=${array[3]}
    length=${array[4]}
    url=${array[5]}
    status=${array[6]}
    response_time=$(echo "${array[7]}" | cut -d '.' -f 1)
}
function count_quantile {
    # array persentage
    declare -a array=("${!1}")
    full_len=${#array[@]}

    sorted_response_array=($(printf '%s\n' "${array[@]}"|sort))
    persentage_count=$(($full_len*$2/100))
    quantile="${sorted_response_array[$persentage_count]}"
}
function count_stats {
    date_to_int $TIMEFROM
    time_from=$DATEINT
    date_to_int $TIMETO
    time_to=$DATEINT
    regex1="^$URL[\?]"
    regex2="^$URL$"

    success_count=0
    not_success_count=0
    response_time_sum=0
    full_count=0
    response_array=()

    while read p || [[ -n "$p" ]]; do
        read_date_time_level_type_length_url_status_response_from_p
        date_to_int $time
        current_time=$DATEINT

        if ( ([[ $url =~ $regex1 ]] || [[ $url =~ $regex2 ]]) && [ "$current_time" -ge "$time_from" ] && [ "$current_time" -le "$time_to" ] );
        then
            response_array["$full_count"]=$response_time
            response_time_sum=$(($response_time_sum+$response_time))
            full_count=$(($full_count+1))
            if (  [ "$status" = "200" ] );
            then
                success_count=$(($success_count+1))
            else
                not_success_count=$(($not_success_count+1))
            fi
        fi
    done <$1

    echo "Statistic for $URL from $TIMEFROM to $TIMETO"
    if [ $full_count -gt 0 ];
    then
        echo "Success requests for $URL:"
        echo $success_count

        echo "Average response time:"
        echo $(($response_time_sum / $full_count))

        count_quantile response_array[@] 95
        echo "95% quantile:"
        echo $quantile

        count_quantile response_array[@] 99
        echo "99% quantile:"
        echo $quantile
    else
        echo "data not found"
    fi
}


while getopts "h?t:u:f:v" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    u)  URL=$OPTARG
        ;;
    f)  TIMEFROM=$OPTARG
        ;;
    t)  TIMETO=$OPTARG
        ;;
    v)  echo "Current version 0.0.1"
        exit 0
    esac
done

shift $((OPTIND-1))

#test for --
[ "$1" = "--" ] && shift

for var in "$@"
do
    count_stats "$var"
done