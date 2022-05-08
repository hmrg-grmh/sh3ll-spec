
historisch ()
{
    : ::: usage ::: :;
    
    : historisch {K} '(f="$(cat -)" && echo "${{K}}" | xargs -i:..{K}..: -- echo "$f") |' 'cat -' K1 K2
    : historisch '' 'local {}="$1" && shift 1 &&' ':' K1 K2
    
    : ::: lib ::: :;
    
    History ()
    {
        local log="${1}" && shift 1 &&
        local mod="${1}" && shift 1 &&
        
        echo "$@" | xargs -n1 | xargs -i"${mod}" -- echo "$log" &&
        :;
    } ;
    
    test function = "$(type -t History)" || { echo :: lib err :History ; return 231 ; } ;
    
    : ::: run '(also lib usage 😛)' ::: :;
    
    eval "$(History 'local {}="${1}" && shift 1 &&' {} head log tail) :" &&
    eval "$(History "$log" "$head" "$@") $tail" &&
    :;
} ;

test function = "$(type -t historisch)" || { echo :: lib err :historisch ; return 231 ; } ;


let "$# == 0" &&
{
    help_doc='
Usage:
    
    now if your app names: foo_blah
    
    1. define and export function named '"'foo_blah'"' include function '"'persch_code', 'persch_parser' and 'persch_run'"' to describe your works
    
    2. run like: '"$0"' 15 minute foo_blah
    
    then the define will out put into the stdin .

E.G.
    
    foo_blah ()
    {
        persch_code ()
        {
            local time_sch="${1:-$(date -d"$day_to_schedule + {} minute" +%FT%T%:::z)}"
            
            echo "
                
                insert into blah.aaa 
                select timestamp, name, value 
                from blah.bbb 
                where timestamp >= $(date -d "$time_sch 15 minute ago" +%s%3N) ;"
        } ;
        
        persch_parser ()
        {
            beeline -u jdbc:hive2://10.1.0.123:10000 "$@"
        } ;
        
        persch_run ()
        {
            persch_code "$schedule_time" | persch_parser -f /dev/stdin
        } ;
    } ;
    
    # then use this to define foo_blah_scheduler:
    '"$0"' 15 minute foo_blah
    
    # then u can use like:
    foo_blah_scheduler 2020-02-02
    
    # or date choose today:
    foo_blah_scheduler

Enjoy 😆' ;
    
    echo "$help_doc" ;
    echo ;
    
    :;
} ;


: main ;


: : defines &&


STEP_TIME_VALUE="${1:-$STEP_TIME_VALUE}" &&
STEP_TIME_TYPE="${2:-$STEP_TIME_TYPE}" &&
APP_NAME="${3:-$APP_NAME}" &&

: &&

:..APP_NAME..:_scheduler ()
{
    day_to_schedule="${1:-$(date +%F)}" || { echo err: date command err ; exit 14 ; } ;
    
    export -f -- :..APP_NAME..: &&
    
    need_to_wait_sec ()
    {
        schedule_datetime_FMT="$1" &&
        time_sec_stamp_now="${2:-$(date +%s)}"
        more_wait_sec="${3:-16}" &&
        
        need_to_wait_s="$(( $(date -d"$schedule_datetime_FMT" +%s) - time_sec_stamp_now + more_wait_sec ))" &&
        
        fu2zero ()
        {
            n=${1:-$need_to_wait_s} &&
            [[ $n == -* ]] &&
            { echo 0 ; } || { echo $n ; } ;
        } &&
        
        fu2zero $need_to_wait_s ;
    } &&

    export day_to_schedule &&
    export -f -- need_to_wait_sec &&
    
    per_count_day ()
    {
        local count_type="$1" && : such as min/sec/hour &&
        local step="$2" && : such as 5 means per 5 min/sec/hour &&
        
        perday_fullcount ()
        {
            local time_type="$1" && : such as min/sec/hour &&
            export ZEROSEC_DATE_FMT="$(date -d@0 +%FT%T%:z)" &&
            
            (
                : 把下面这个定义完整地随便复制到哪儿 ;
                : 然后给传参 day/min/sec 之类的试试效果 ;
                : 就知道它是怎么回事儿啦 ;
                : 别的函数也是一样！ ) &&
            
            per_type_sec ()
            {
                local type="$1" &&
                local Z="${2:-$ZEROSEC_DATE_FMT}" &&
                
                : 核心逻辑就只有下面这一行 : &&
                date -d "$Z next ${type:-day}" +%s &&
                
                :;
            } &&
            
            echo $(( "$(per_type_sec day)" / "$(per_type_sec "$time_type")" )) &&
            
            :;
        } &&
        
        seq -- 0 "$step" "$(( $(perday_fullcount "$count_type") - "$step" ))" &&
        
        :;
    } &&
    
    
    per_count_day :..STEP_TIME_TYPE..: :..STEP_TIME_VALUE..: |
        
        xargs -P1 -i -- bash -c '
            
            # per :..STEP_TIME_VALUE..: :..STEP_TIME_TYPE..:
            export schedule_time="$(date -d"$day_to_schedule + {} :..STEP_TIME_TYPE..:" +%FT%T%:::z)" ;
            
            # wait if time have to
            sleep $(need_to_wait_sec "$schedule_time" "$(date +%s)" 12)s ;
            
            '"$(declare -f -- :..APP_NAME..:) ; "':..APP_NAME..: && persch_run 2>&1 | tee :..APP_NAME..:.$schedule_time.log &&
            
            { echo ::..APP_NAME..:.line :succ :d :: $day_to_schedule ::..STEP_TIME_TYPE..: :: {} >&2 ; } ||
            { echo ::..APP_NAME..:.line :fail :d :: $day_to_schedule ::..STEP_TIME_TYPE..: :: {} >&2 ; } ' &&
    
    
    :;
} &&

export -f -- :..APP_NAME..:_scheduler &&
export -- APP_NAME STEP_TIME_TYPE STEP_TIME_VALUE &&


: : : &&


eval "$(
    
    : : runs to make codes &&
    
    echo APP_NAME |
        
        xargs -i -- $SHELL -c 'echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' |
        
        historisch '{}' '(f="$(cat -)" && echo "${}" | xargs -i:..{}..: -- echo "$f") | ' 'cat -' STEP_TIME_TYPE STEP_TIME_VALUE )" &&

: : after define by eval &&
: : show this define &&

declare -f -- "${APP_NAME}_scheduler" &&

:;

exit $? ;


: olds ;

# : STEP_TIME_VALUE STEP_TIME_TYPE APP_NAME
# 
# 
# 
# 
# : way 1 :
# 
# eval "$(
#     
#     echo "$STEP_TIME_VALUE" | xargs -i:..STEP_TIME_VALUE..: -- $SHELL -c "
#         
#         $(
#             echo "$STEP_TIME_TYPE" | xargs -i:..STEP_TIME_TYPE..: -- $SHELL -c "
#                 
#                 $(
#                     echo APP_NAME | xargs -i -- $SHELL -c '
#                         
#                         echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' ) &&
#                 
#                 declare -f -- ${APP_NAME}_scheduler " ) &&
#         
#         declare -f -- ${APP_NAME}_scheduler " )" &&
# 
# declare -f -- ${APP_NAME}_scheduler ;
#     
#     
# : way 2 :
# 
# echo APP_NAME | xargs -i -- $SHELL -c '
#     echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' |
#     
#     (f="$(cat -)" && echo "$STEP_TIME_TYPE" | xargs -i:..STEP_TIME_TYPE..: -- $SHELL -c "$(echo "$f") && declare -f -- ${APP_NAME}_scheduler") |
#     (f="$(cat -)" && echo "$STEP_TIME_VALUE" | xargs -i:..STEP_TIME_VALUE..: -- $SHELL -c "$(echo "$f") && declare -f -- ${APP_NAME}_scheduler") |
#     
#     cat - ;
# 
# : way 3 :
# 
# echo APP_NAME | xargs -i -- $SHELL -c '
#     echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' |
#     
#     eval "
#         $(
#             
#             echo STEP_TIME_TYPE STEP_TIME_VALUE |
#                 
#                 xargs -n1 |
#                 xargs -i -- echo '
#                     
#                     (f="$(cat -)" && echo "${}" | xargs -i:..{}..: -- $SHELL -c "$(echo "$f") && declare -f -- ${APP_NAME}_scheduler") |' )
#         cat - "




#         eval "
#             
#             $(
#                 
#                 echo STEP_TIME_TYPE STEP_TIME_VALUE |
#                     
#                     xargs -n1 |
#                     xargs -i -- echo '
#                         
#                         (f="$(cat -)" && echo "${}" | xargs -i:..{}..: -- echo "$f") |' )
#             
#             cat - "


