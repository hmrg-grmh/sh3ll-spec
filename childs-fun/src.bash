
: 下面的命名方式不支持 POSIX SHell ;
: 不过我也没打算支持 ... 它就是个交互式的工具 ;
: 想用脚本就用 bash 就好了 ;



erot ()
{
    :;
    
    innerfun ()
    {
        bodies: ()
        {
            :;
            
            echo '"$@" ; local ret=$? ;' &&
            echo 'unset -f -- '"$*"' ; return $ret ;' ;
        } &&
        
        
        couple ()
        {
            tailend:: ()
            {
                :;
                
                local obj_name="${1:-gegenständliche}" &&
                local fills="${2:-fills:}" &&
                local nackt="${3:-nackt:}" &&
                
                bodies: "$obj_name"_"$fills" "$obj_name"_"$nackt" ;
            } &&
            
            tailend_conf::: () { tailend:: conf "$@" ; } &&
            
            eval "$(bodies: tailend:: tailend_conf:::)"
        } &&
        
        
        eval "$(bodies: bodies: couple)" ;
    } &&
    
    eval "$(innerfun bodies: innerfun)" ;
} ;
