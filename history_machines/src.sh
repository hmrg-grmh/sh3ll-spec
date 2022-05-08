

historisch ()
{
    : '历史性（ historisch ）就是历史（ History ）的使用例。'
    : '"历史什么也没有做"。'
    
    
    : ::: 使用例 ::: :;
    : ::: usage ::: :;
    
    : historisch {K} '(f="$(cat -)" && echo "${{K}}" | xargs -i:..{K}..: -- echo "$f") |' 'cat -' K1 K2
    : historisch {K} '(f="$(cat -)" && echo "${{K}}" | xargs -i:_{K}_: -- echo "$f") |' 'cat -' K1 K2
    : historisch {} 'local {}="$1" && shift 1 &&' ':' K1 K2
    
    
    : ::: 知识 ::: :;
    : ::: lib ::: :;
    
    History ()
    {
        : 'Today, is History !!'
        : 'Today, we Make History !!'
        : 'and Today, we Are the Part of History !!'
        
        : '"历史（ History ）什么也没有做"。'
        : '"The History did Nothing ."'
        
        : ::: 使用例 ::: :;
        : ::: usage ::: :;
        
        #: eval "$(History '(f="$(cat -)" && echo "${{K}}" | xargs -i:..{K}..: -- echo "$f") |' '{K}' K1 K2) cat -"
        #: eval "$(History 'local {}="$1" && shift 1 &&' '' K1 K2) :"
        
        : ::: 代码 ::: :;
        : ::: codes ::: :;
        
        local log="${1}" && shift 1 &&
        local mod="${1}" && shift 1 &&
        
        echo "$@" | xargs -n1 | xargs -i"${mod}" -- echo "$log" &&
        
        :;
    } ;
    
    test function = "$(type -t History)" || { echo :: lib err 😅 ; return 231 ; } ;
    
    : ::: run '(also lib usage 😛)' ::: :;
    
    : 接下来正常是写这三行 但我不直接写
    
    : 'local head="${1}" && shift 1 &&'
    : 'local log="${1}" && shift 1 &&'
    : 'local tail="${1}" && shift 1 &&'
    
    : 下面就是对上面代码的生成并应用 相当于写了上面三行
    
    : 这里的变量定义是之后使用的前提
    : 之后的使用也是对变量代码的概括
    
    : 尝试实践在先理论总结在后
    : 理论总结实现实践依赖实践
    
    : 而历史什么都没做
    : 但做了（eval）才展开出（也即生成出）历史的特性
    : （做了才能发挥作用才能称为使用例成为实现的完成）
    
    
    eval "$(History 'local {}="${1}" && shift 1 &&' {} head log tail) :" &&
    
    eval "$(History "$log" "$head" "$@") $tail" &&
    :;
} ;


: :: simple :: :;


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
    
    test function = "$(type -t History)" || { echo :: lib err 😅 ; return 231 ; } ;
    
    : ::: run '(also lib usage 😛)' ::: :;
    
    eval "$(History 'local {}="${1}" && shift 1 &&' {} head log tail) :" &&
    eval "$(History "$log" "$head" "$@") $tail" &&
    :;
} ;



: :::::::::::::::::::::: :



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


per_count_day_classic ()
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


