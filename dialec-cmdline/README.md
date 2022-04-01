一个阻塞当前执行进度并向用户发起提问的「框架」。



一次性注册：

~~~ sh
. dialec-cmdline/src.sh
dialec_cmdlines
~~~

使用例：

定义如下

~~~ sh
docker_fsmake__ ()
{
    local rt ;
    
    dev_uuid ()
    { local device="$1" && local field="$2" && (eval "$(blkid -o export -- "$device")"' ; echo $'"${field:-UUID}") ; } &&
    
    docker_fstab ()
    { local device="$1" && local dir="${2:-/var/lib/docker}" && echo UUID="$(dev_uuid "$device" UUID)"  "${dir:-/var/lib/containers}"  "$(dev_uuid "$device" TYPE)"  defaults,pquota  0 0 ; } &&
    
    : : : : &&
    
    local device="$1" &&
    local dir="$2" &&
    
    mkdir -p -- "$dir" &&
    
    : 下边都是如果回答 n 就退出'(quit)' docker_fsmake__ 否则就会执行到下边 &&
    
    {
        ask_user "got dev: $device and dir: $dir " "make the $device in to xfs ? will clear datas in it ~~ 😬" "[y/n]" '
            
            case "$ans" in 
                y) return 0 ;; 
                n) echo : quit tool 😋 ; return 2 ;;
                *) ;; esac ' || return ;
        
        mkfs -t xfs -n ftype=1 -f -- "$device" ;
        
    } &&
    
    
    {
        ask_user "
will add this to fstab:
$(docker_fstab "$device" "$dir")
" '🤔 go on ?' '[y/n]' '
            
            case "$ans" in
                y) return 0 ;;
                n) echo : quit tool 😘 ; return 2 ;;
                *) ;; esac ' || return ;
        
        (echo ; docker_fstab "$device" "$dir" ; echo) | tee -a -- /etc/fstab ;
        
    } &&
    
    
    mount -a ||
    { rt=$? ; echo 😨 need to check /etc/fstab and recmd mount -a ; return $rt ; } ;
    
    lsblk &&
    
    :;
} ;
~~~

然后就可以使用了，譬如：

- `docker_fsmake__ /dev/sdx /var/lib/docker`
- `docker_fsmake__ /dev/sdx /var/lib/containers`

这会问你要不要格式化 `/dev/sdx` ，格式化参数已经写成了建议的样子（ `mkfs -t xfs -n ftype=1 -f -- "$device"` ），回答 `y` 就会格式化；然后会再问你要不要把刚刚新盘的挂载信息加入到 `/etc/fstab` ，并根据回答来执行或者不执行这件事。

