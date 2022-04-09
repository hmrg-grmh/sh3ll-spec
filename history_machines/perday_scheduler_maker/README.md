# 介绍

这是个工具。

里面用到的技术点（我认为的）有两方面：

- 对 `date` 和 `sleep` 的灵活使用
- 借助 `eval` 实现一种 Fold 的变化

在 `: main ;` 之前的是帮助文档，之后的就是程序代码。不带参数执行脚本就会吐出帮助文档。

## 目的

我的目的就是，使用这个工具并传递相应的参数，它就会生成一种特定的调度逻辑。

比如，我的传参如果分别是 `15` `minute` `foo_blah` ，则会生成针对 `foo_blah` 定义中描述的工作的每十五分钟调度的工具。

那么，执行那个**被生成出来**的工具（会是一个名为 `foo_blah_scheduler` 的 SHell 函数），效果就是：在第一个参数位置告诉它一个具体的日期，那么它就会等到这一天的时候，每十五分钟一次地执行 `foo_blah` 定义中描述的工作。前一次执行完才会开始执行后一次，而如果实际的调度时间已经过了，它就会立刻执行。

在 `foo_blah` 定义中可以使用一个叫 `schedule_time` 的变量，它和实际执行时间无关，它的内容就是当次应当调度的时间——是一个被格式化为了 `+%FT%T%:::z` 的日期格式。而从日期的格式化格式也可以看出，目前我并没有做比 *秒* 更加精确的调度器的生成支持。另外，这也使得直接使用 `foo_blah` 定义中的函数有可能失败，如果它里面用到了这个变量的话。但你也可以吧这个变量赋值，这样就能测试你定义的 `foo_blah` 的效果了。

## 解析

### 时间魔术

这部分介绍一下 `:..APP_NAME..:_scheduler` 模板中涉及到的模板无关的内容。

主要的东西就是下边这两样。

（虽说我叫它魔术，但其实是一些挺朴实的东西……）

#### `need_to_wait_sec`

这个定义要达到的效果很简单：我给它一个目标时间、一个现在时间（可省略），它就能给出从现在到达目标时间要花多少秒的结论。

如果目标时间已经过去，需要给我的结论就应当是 `0` 。

第三个参数顾名思义：多等会儿。

定义：

~~~~ sh
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
~~~~

我制作它，就是为了用 `sleep` 停顿正确的时间。那个多等会儿的第三个参数，是用来延长这个时间的。

使用时我倾向于把第二个参数给写上，那么这个工具就是类似于「无副作用函数」一样的东西了——就是说，你只看调用时候的参数就能掌握它的全貌，它不会背地里做什么、你不需要一次次地关心它怎么定义的。

使用的代码在下边，这个地方： `sleep $(need_to_wait_sec "$schedule_time" "$(date +%s)" 12)s` 。

#### `per_count_day`

这个工具要做的效果很简单：

- 让 `per_count_day minute 15` 等效于 `seq -- 0 15 1425`
- 让 `per_count_day minute 5` 等效于 `seq -- 0 15 1435`
- 以此类推……

定义：

~~~~ sh
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
~~~~

一开始我用的是这个定义：

~~~~ sh
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
~~~~

这个老的定义读起来其实也是更顺眼的，因为分支都明白写着了，对于不同的 `date` 使用也是相对直观的。

但我为啥做了新定义呢？短只是一方面，主要的原因就在于，实现这个工具的必要逻辑，在 `date` 这个工具里已经实现好了。新的定义就是单纯在复用 `date` 工具内部已经实现好的分支逻辑，所以说，它看起来就会不是那么明白。

——但是不用担心，新旧定义都是 *无副作用* 的，你可以随意复制出来测试它，或者复制到任何哪个 SHell 代码里去用（合乎使用许可地）。

通过刺探性的测试，比如（在定义后）尝试运行一下 `per_type_sec minute` 、 `per_type_sec min` 或者 `per_type_sec hour` ，你就会明白它的效果究竟是什么。其实只是很简单的东西，定义起来麻烦在于，要确保用一种足够标准、无干扰、且不多余的形式，去使用 `date` 。

最终就是要拼凑出相应的 `seq` 命令了。别的什么也没有做。


### 模板生成目标

其实就是把特定的字符串替换成特定的值。

最容易让人想到的就是用 `sed` 了，我可以 `declare -f` 我那个模板函数，然后管道给编写好了特定规则的 `sed` 让它替换去。

——这其实是最合理的做法。不过，这里我想要尽量少引入对二进制文件的依赖。虽说应该也没啥 GNU/Linux 系统会没有 `sed` 这个命令……（容器基础镜像的话倒是有可能没有！）

由于 `xargs -i` 就能达到我所需要的替换效果，而这个工具本身也用到了 `xargs` ，所以我考虑了基于它的替换方案。

*只要执行过 `: : defines &&` 到 `: : runs &&` 之间的，所有定义性质的命令了，并且对三个变量也直接赋值过了，那么这里（即 `: : runs &&` 以下）的代码就都可以在这个上下文中直接测试了。建议在你自己的 Bash 上亲自测测看效果。直接把代码复制上去就可以，随便哪一部分。（如果在最后还是总是得到 `> ` 的提示符，可以考虑输入 `:` 后回车。）*

*考虑到函数命名，这里需要的 SHell 不能是一般的 POSIX SHell 了。这里我用的是 `bash` 。*


#### 旧的抽象过程记录（可跳过）

中间出了一些错误，有一些不必要的冗余。

这个不必要的荣誉就出在第一阶段使用的方案上：

~~~~ bash
eval "$(
    
    echo "$STEP_TIME_VALUE" | xargs -i:..STEP_TIME_VALUE..: -- $SHELL -c "
        
        $(
            echo "$STEP_TIME_TYPE" | xargs -i:..STEP_TIME_TYPE..: -- $SHELL -c "
                
                $(
                    echo APP_NAME | xargs -i -- $SHELL -c '
                        
                        echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' ) &&
                
                declare -f -- ${APP_NAME}_scheduler " ) &&
        
        declare -f -- ${APP_NAME}_scheduler " )" &&

declare -f -- ${APP_NAME}_scheduler ;
~~~~

然后基于上述更改形式得到：

~~~~ bash
echo APP_NAME | xargs -i -- $SHELL -c '
    echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' |
    
    (f="$(cat -)" && echo "$STEP_TIME_TYPE" | xargs -i:..STEP_TIME_TYPE..: -- $SHELL -c "$(echo "$f") && declare -f -- ${APP_NAME}_scheduler") |
    (f="$(cat -)" && echo "$STEP_TIME_VALUE" | xargs -i:..STEP_TIME_VALUE..: -- $SHELL -c "$(echo "$f") && declare -f -- ${APP_NAME}_scheduler") |
    
    cat - ;
~~~~

再用 `eval` 抽象最终得到：

~~~~ bash
echo APP_NAME | xargs -i -- $SHELL -c '
    echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' |
    
    eval "
        $(
            
            echo STEP_TIME_TYPE STEP_TIME_VALUE |
                
                xargs -n1 |
                xargs -i -- echo '
                    
                    (f="$(cat -)" && echo "${}" | xargs -i:..{}..: -- $SHELL -c "$(echo "$f") && declare -f -- ${APP_NAME}_scheduler") |' )
        cat - "
~~~~

刚刚在写这个文档的过程中，在分析代码为啥这么写的时候，发现最开始方式中不必要的冗余。

所以，这个部分我就不细说，读者也不需要看，直接跳过看下面的部分就好。



#### 抽象的过程

分三步：

- 先用最朴素的办法去写（我会详细说说定义内容的替换阶段）
- 然后转换成管道的形式（把上一个方式用管道的形式来写）
- 然后再抽象（这里就会用到 `eval` 了）


##### 方式 1 : 先不管 Fold 的事情

最开始先不考虑啥 Fold 不 Fold 的，先以最朴素的形式写出来：

~~~~ bash
eval "$(
    
    echo "$STEP_TIME_VALUE" | xargs -i:..STEP_TIME_VALUE..: -- echo "$(
        
        echo "$STEP_TIME_TYPE" | xargs -i:..STEP_TIME_TYPE..: -- echo "$(
            
            echo APP_NAME | xargs -i -- $SHELL -c '
                
                echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' )" )" )" &&

declare -f -- ${APP_NAME}_scheduler ;
~~~~

其中有三步。或者说三个阶段——一个阶段对应一次替换。

###### 阶段一

先是用它得到第一个阶段结果：

~~~~ bash
echo APP_NAME | xargs -i -- $SHELL -c '
    
    echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" '
~~~~

这个阶段只是替换了目标函数的函数名。

然后呢，我要让这结果进入字符串。这是为之后阶段做的准备。、

下面的代码和上面效果一样：

~~~~ bash
echo "$(
    
    echo APP_NAME | xargs -i -- $SHELL -c '
        
        echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' )"
~~~~

###### 阶段二

在 *阶段一* 的最后那块代码的前面，加上一点东西，得到下面的代码：

~~~~ bash
echo "$STEP_TIME_TYPE" | xargs -i:..STEP_TIME_TYPE..: -- echo "$(
    
    echo APP_NAME | xargs -i -- $SHELL -c '
        
        echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' )"
~~~~

执行以下可以看到，这一次， `STEP_TIME_TYPE` 被替换成了对应的值。

还是同样的道理，它要进字符串：

~~~~ bash
echo "$(
    
    echo "$STEP_TIME_TYPE" | xargs -i:..STEP_TIME_TYPE..: -- echo "$(
        
        echo APP_NAME | xargs -i -- $SHELL -c '
            
            echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' )" )"
~~~~

###### 阶段三

在 *前一阶段* 的最后那块代码的前面加上点儿东西：

~~~~ bash
echo "$STEP_TIME_VALUE" | xargs -i:..STEP_TIME_VALUE..: -- echo "$(
    
    echo "$STEP_TIME_TYPE" | xargs -i:..STEP_TIME_TYPE..: -- echo "$(
        
        echo APP_NAME | xargs -i -- $SHELL -c '
            
            echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' )" )"
~~~~

这样，所有的替换就都完成了。

其实如果单说这个工具的功能的话，**到这里已经可以结束了**。

但是这样也只是把定义打印出来。其实到这里已经可以了，但如果想要在当前上下文使用这个定义，就要再进一次字符串：

~~~~ bash
eval "$(
    
    echo "$STEP_TIME_VALUE" | xargs -i:..STEP_TIME_VALUE..: -- echo "$(
        
        echo "$STEP_TIME_TYPE" | xargs -i:..STEP_TIME_TYPE..: -- echo "$(
            
            echo APP_NAME | xargs -i -- $SHELL -c '
                
                echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' )" )" )"
~~~~

并在下面用 `declare` 基于它的名字来打印定义。

##### 方式 2 : 把上述的写法改成基于管道的

结果：

~~~~ bash
echo APP_NAME | xargs -i -- $SHELL -c '
    echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' |
    
    (f="$(cat -)" && echo "$STEP_TIME_TYPE" | xargs -i:..STEP_TIME_TYPE..: -- echo "$f") |
    (f="$(cat -)" && echo "$STEP_TIME_VALUE" | xargs -i:..STEP_TIME_VALUE..: -- echo "$f") |
    
    cat - ;
~~~~

这个版本其实是看起来最明确的。

第一阶段就是这个：

~~~ bash
echo APP_NAME | xargs -i -- $SHELL -c '
    echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" '
~~~

第二阶段就加上这个：

~~~ bash
echo APP_NAME | xargs -i -- $SHELL -c '
    echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' |
    
    (f="$(cat -)" && echo "$STEP_TIME_TYPE" | xargs -i:..STEP_TIME_TYPE..: -- echo "$f")
~~~

第三阶段：

~~~ bash
echo APP_NAME | xargs -i -- $SHELL -c '
    echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' |
    
    (f="$(cat -)" && echo "$STEP_TIME_TYPE" | xargs -i:..STEP_TIME_TYPE..: -- echo "$f") |
    (f="$(cat -)" && echo "$STEP_TIME_VALUE" | xargs -i:..STEP_TIME_VALUE..: -- echo "$f")
~~~

再为了统一以下结尾符形式，就最后再加个 ` | cat - ` 。

成了。

##### 方式 3 : 可以抽象了

这个基于 *方式 2* 中得到的结果。

抽象后的结果：

~~~~ bash
echo APP_NAME | xargs -i -- $SHELL -c '
    echo "${}" | xargs -i:..{}..: -- echo "$(declare -f -- :..{}..:_scheduler)" ' |
    
    eval "
        
        $(
            
            echo STEP_TIME_TYPE STEP_TIME_VALUE |
                
                xargs -n1 |
                xargs -i -- echo '
                    
                    (f="$(cat -)" && echo "${}" | xargs -i:..{}..: -- echo "$f") |' )
        
        cat - "
~~~~

嗯。看起来，代码变多了。在（我认为必要的）格式化后。

它是完全由 *方式 2* 变来的。在 `eval` 里的是除去 *阶段一* 以后的一切。 *方式 2* 里最后的所谓「要统一一下结尾的形式」也是为了这里。

具体说来，你可以试试看这个代码的执行效果：

~~~ sh
echo STEP_TIME_TYPE STEP_TIME_VALUE |
    
    xargs -n1 |
    xargs -i -- echo '
        
        (f="$(cat -)" && echo "${}" | xargs -i:..{}..: -- echo "$f") |'
~~~

它是不是给你打出来了我上面说过的「要统一一下结尾的形式」的那两行代码？

那么把它的这个结果丢给 `eval` （并加上必要的结尾的 `cat -` 这部分），这字符串就会被当作代码，在当前的上下文得到解析。

然后……效果就是和 *方式 2* 一致的效果了……

而「要统一一下结尾的形式」那两句里面的唯一的不同，也因为抽象，被直接放在了开头的一个单独的位置。

不像之前的那两个「库」，这个「工具」的话，实现起来并不需要非得用 *方式 3* 。用 *方式 1* 就足够，可读性的话 *方式 2* 则是最好的。

但，正所谓「有再二就会有再三」，既然统一的形式已经呼之欲出，那么，要不要真的抽象它出来，就只是做不做的问题了。

——而事实上，也只有真的做了，才能证明，那个「统一的形式」，究竟是怎样子的一个形式。

……

所以就有了这个 *方式 3* ——不同于另外那两个「库」是必须用到 `eval` （或者说叫 *元编程* 这么个称呼），这里对它的使用，更像是一种精力过剩的情况下的对我只是「感到可以抽象」的可能性的确证行动。

工程上不建议如此，还是那个结论， *方式 2* 中开头给出的结果就是最佳的。因为它里面的统一形式一眼就能看出来，而**在本工具的定义里如果今后不再扩充更多变量则那样就刚好足够**。

在这个工具里， *方式 3* 只是一个证明。

但我还是用了它，因为，万一之后要扩充这个工具的能力呢？比如再增加一个可传参数用来影响日期的格式化从而给工具增加更细的调度粒度支持？

所以，我就还是用了它了。




