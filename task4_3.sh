#!/bin/bash

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

function show_help {
   cat << EOF
Usage: task4_1 [OPTION]... [FILE]...
Count 95% quantile request time for urls for each hour for specific day and plot them with gnuplot

  -u    urls in format url1;url2;...;urln;
  -d    date in format YYYY-MM-DD
  -h    display this help and exit
  -v    output version information and exit

Examples:
  task4_3.sh -u "/user;/resume;/vacancy" -d "2013-01-18" log.txt
  Count 95% quantile for /user /resume /vacancyerror for day 2013-01-18 and plot stats

Report task4_3 bugs to overmes@gmail.com
EOF
}
function date_to_int {
    DATEINT=`date -d "1970-01-01 $1" +%s`
}
function read_date_time_level_type_length_url_status_response_from_p {
    date=$(echo $p | cut -f1 -d ' ')
    time=$(echo $p | cut -f2 -d ' ')
    level=$(echo $p | cut -f3 -d ' ')
    type=$(echo $p | cut -f4 -d ' ')
    length=$(echo $p | cut -f5 -d ' ')
    url=$(echo $p | cut -f6 -d ' ')
    status=$(echo $p | cut -f7 -d ' ')
    response_time=$(echo $p | cut -f8 -d ' ' | cut -d '.' -f 1)
}
function count_quantile {
    # array persentage
    declare -a array=("${!1}")
    full_len=${#array[@]}

    sorted_response_array=($(printf '%s\n' "${array[@]}"|sort))
    persentage_count=$(($full_len*$2/100))
    quantile="${sorted_response_array[$persentage_count]}"
}
function write_quantile {
    if [ ${#response_array[@]} -gt 0 ];
    then
        count_quantile response_array[@] 95
        echo "url: $element    hour: $previous_hour     95% quantile: $quantile"
    fi
    full_count=0
    response_array=()
    echo "$previous_hour $quantile" >> data.dat
}
function count_stats {

    echo "#plot data" > data.dat
    IFS=';' read -a urls_array <<< "$URLS"
    for element in "${urls_array[@]}"
    do
        regex1="^$element\?.*"
        regex2="^$element$"
        full_count=0
        response_array=()
        echo "#$element" >> data.dat

        while read p || [[ -n "$p" ]]; do
            read_date_time_level_type_length_url_status_response_from_p

            if ( ([[ $url =~ $regex1 ]] || [[ $url =~ $regex2 ]]) && [[ $date = $DATE ]] );
            then
                if [ -z "$current_hour" ];
                then
                    previous_hour=$(echo $time | cut -d ":" -f 1)
                else
                    previous_hour=$current_hour
                fi

                current_hour=$(echo $time | cut -d ":" -f 1)
                response_array["$full_count"]=$response_time
                full_count=$(($full_count+1))

                if [ "$previous_hour" != "$current_hour" ];
                then
                    write_quantile
                fi
            fi
        done <$1

        write_quantile
        unset current_hour
        unset previous_hour

        echo -en '\n\n' >> data.dat
    done
}


while getopts "h?d:u:v" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    u)  URLS=$OPTARG
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

colors=("#FF0000" "#800000" "#FFFF00" "#808000" "#00FF00" "#008000" "#00FFFF" "#008080" "#0000FF" "#000080" "#FF00FF" "#800080")

plot_string="set xlabel 'Hour (hour)'; set ylabel 'Time (ms)'"
IFS=';' read -a urls_array <<< "$URLS"

for i in "${!urls_array[@]}"; do
  plot_string="$plot_string;set style line $(($i + 1)) lc rgb '${colors[$i]}' lt 1 lw 2 pt 7 ps 1.5"
done

plot_string="$plot_string;plot[0:23] "
for i in "${!urls_array[@]}"; do
  plot_string="$plot_string 'data.dat' index $i with linespoints ls $(($i + 1)) title '${urls_array[$i]}',"
done

gnuplot -p -e "$plot_string; pause 1000;" &
exit 0