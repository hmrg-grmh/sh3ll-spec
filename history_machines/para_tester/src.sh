: simple defination:

    para_tester ()
    {
        (
            eval "
                $(
                    echo "$@" | xargs -n1 |
                        xargs -i -- echo 'test ! -z "${}" &&' )
                : " ) ||
        {
            1>&2 echo para err: $(
                eval "$(
                    echo "$@" | xargs -n1 |
                        xargs -i -- echo 'echo {}="'"'"'${}'"'"'" ' )" ) ;
            return 232 ; } ;
    } ;

: use historisch:

    para_tester ()
    {
        (
            eval "$(historisch 'test ! -z "${}" &&' "$@") :" ) ||
        {
            1>&2 echo para err: $(
                eval "$(historisch 'echo {}="'"'"'${}'"'"'" ' "$@")" ) ;
            return 232 ; } ;
    } ;

: usage:

    para_tester local_var_1 exported_var_2 foo_bar_3 || { return $? ; } ;
    
    : it will test length of these three var and if one is zero then quit with code 232 ...
    : idea from: https://github.com/yhm-amber/container-note/blob/main/build-practices/simple-proxy/get-stream-conf.sh
