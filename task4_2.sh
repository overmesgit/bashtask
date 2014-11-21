#!/bin/bash

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

function show_help {
   cat << EOF
Usage: task4_2 [OPTION]... [FILE]...
Count average and median request time for profile in specific day

  -i    profile id
  -d    date in format YYYY-MM-DD
  -h    display this help and exit
  -v    output version information and exit

Examples:
  task4_2.sh -d 2013-01-18 -i 1 log.txt
  Output stats for profile with id 1 in date 2013-01-18

Report task4_2 bugs to overmes@gmail.com
EOF
}
function count_quantile {
    # array persentage
    declare -a array=("${!1}")
    full_len=${#array[@]}

    sorted_response_array=($(printf '%s\n' "${array[@]}"|sort))
    persentage_count=$(($full_len*$2/100))
    quantile="${sorted_response_array[$persentage_count]}"
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
function count_stats {
    regex="^/resume[\?].*id=$ID.*"

    response_time_sum=0
    full_count=0
    response_array=()

    while read p || [[ -n "$p" ]]; do
        read_date_time_level_type_length_url_status_response_from_p
        if ( [[ $url =~ $regex ]] && [[ $date = $DATE ]] );
        then
            response_array["$full_count"]=$response_time
            response_time_sum=$(($response_time_sum+$response_time))
            full_count=$(($full_count+1))
        fi
    done <$1

    echo "Statistic for profile with id=$ID for date $DATE"
    if [ $full_count -gt 0 ];
    then
        echo "Average response time:"
        echo $(($response_time_sum / $full_count))

        count_quantile response_array[@] 50
        echo "Median:"
        echo $quantile
    else
        echo "data not found"
    fi
}


while getopts "h?i:d:v" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    i)  ID=$OPTARG
        ;;
    d)  DATE=$OPTARG
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