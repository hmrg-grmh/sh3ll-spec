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
} ;

per_count_day ()
{
    count_type="$1" && : such as min/sec/hour &&
    step="$2" && : such as 5 means per 5 min/sec/hour &&
    
    perday_fullcount ()
    {
        perday_sec="$(date -d1970-01-02T00:00:00+00:00 +%s)" &&
        
        case "$1" in
            
            m|min|minute)
                
                permin_sec="$(date -d1970-01-01T00:01:00+00:00 +%s)" &&
                echo $(( perday_sec / permin_sec )) && return 0 ;;
            
            h|hour)
                
                perhour_sec="$(date -d1970-01-01T01:00:00+00:00 +%s)" &&
                echo $(( perday_sec / perhour_sec )) && return 0 ;;
            
            s|sec|second)
                
                echo $(( perday_sec )) && return 0 ;;
            
        esac || return $? ;
    } &&
    
    seq -- 0 "$step" "$(( $(perday_fullcount "$count_type") - "$step" ))" ;
} ;

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
            : 别的函数也是一样！！ ) &&
        
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
} ;


