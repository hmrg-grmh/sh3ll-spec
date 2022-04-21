一个阻塞当前执行进度并向用户发起提问的「框架」。



一次性注册：

~~~ sh
. dialec-cmdline/src.sh
dialec_cmdlines
~~~

使用例：

定义如下

~~~ sh
uuid_xfstab__ ()
{
    local rt ;
    
    case "$#" in 1|2) ;; *) 1>&2 echo need one or two args ; return 4 ;; esac ;
    
    : ::::::::::::::::: : ;
    
    dev_uuid ()
    {
        local device="$1" &&
        local field="$2" &&
        (eval "$(blkid -o export -- "$device")"' ; echo $'"${field:-UUID}") ;
    } &&
    
    uuid_fstab ()
    {
        local device="$1" &&
        local dir="${2:-/var/lib/docker}" &&
        
        echo UUID="$(
            dev_uuid "$device" UUID )"  "${dir:-/var/lib/containers}"  "$(
            dev_uuid "$device" TYPE )"  defaults,pquota  0 0 ;
    } &&
    
    : ::::::::::::::::: : &&
    
    local device="$1" &&
    local dir="${2:-/var/lib/libvirt/images/pool0}" &&
    
    mkdir -p -- "$dir" &&
    
    : 下边都是如果回答 n 就退出'(quit)' uuid_xfstab__ 否则就会执行到下边 &&
    
    {
        ask_user "
$(lsblk)

========

: got 
: 
:   dev: $device 
:   dir: $dir 
" ": make the $device in to xfs ? will clear datas in it ~~ 😬" "[y/n]" '
            
            case "$ans" in 
                y) echo ; return 0 ;; 
                n) echo : quit tool 😋 ; return 2 ;;
                *) ;; esac ' || return ;
        
        mkfs -t xfs -n ftype=1 -f -- "$device" ;
        
    } &&
    
    
    {
        ask_user "
: will add this line to fstab:
$(uuid_fstab "$device" "$dir")
" ': 🤔 go on ?' '[y/n]' '
            
            case "$ans" in
                y) echo ; return 0 ;;
                n) echo : quit tool 😘 ; return 2 ;;
                *) ;; esac ' || return ;
        
        (echo ; uuid_fstab "$device" "$dir" ; echo) | tee -a -- /etc/fstab ;
        
    } &&
    
    
    mount -a ||
    { rt=$? ; echo 😨 may need to check /etc/fstab and recmd mount -a ; return $rt ; } ;
    
    lsblk &&
    
    :;
} ;
~~~

然后就可以使用了，譬如：

- `uuid_xfstab__ /dev/sdx /var/lib/docker`
- `uuid_xfstab__ /dev/sdx /var/lib/containers`

这会问你要不要格式化 `/dev/sdx` ，格式化参数已经写成了建议的样子（ `mkfs -t xfs -n ftype=1 -f -- "$device"` ），回答 `y` 就会格式化；然后会再问你要不要把刚刚新盘的挂载信息加入到 `/etc/fstab` ，并根据回答来执行或者不执行这件事。

或者，如果你在用 `snapper` 管理系统快照的话，建议的做法是：

~~~ sh
ask_user ()
{
    predesc="${1:-Hey 👻}"
    ask="${2:-what should i ask ???}" &&
    anss="${3:-[y/n] (:p)}" &&
    
    cases="${4:-
        case \"\$ans\" in 
            
            y|\'\') echo 😦 yup\?\? ; break ;; 
            n) echo 🤔 no\? ; break ;; 
            *) echo 🤨 ahh\? what is \'\$"{"ans:-:p"}"\' \? ;; esac }" &&
    
    
    echo "$predesc" &&
    while read -p "$ask $anss " -- ans ;
    do eval "$cases" ; done ;
} ;
~~~

*（这个其实就是上面的「一次性注册」）*

然后：

~~~~ bash
snapper create -d 'uuid-xfstab: /dev/sdx /var/lib/docker' --command "$(declare -f -- ask_user uuid_xfstab__) ; uuid_xfstab__ /dev/sdx /var/lib/docker"
snapper create -d 'uuid-xfstab: /dev/sdx /var/lib/containers' --command "$(declare -f -- ask_user uuid_xfstab__) ; uuid_xfstab__ /dev/sdx /var/lib/containers"
~~~~

**由 `ask_user` 提供的交互的功能依然能被正常使用。**

*（顺便，对于 `/var/lib/libvirt/images/pool` 也可以这样做。）*



