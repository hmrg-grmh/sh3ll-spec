# 使用

查看帮助：

~~~~ sh
bash perday_scheduler_maker/src.sh
~~~~

使用：

~~~~ sh
bash perday_scheduler_maker/src.sh 15 minute foo_blah
~~~~

这样就会生成一个在当前上下文定义好了的 `foo_blah_scheduler` 函数，传参某个日期（如果没传参就默认是当天）执行它，它就会发生这天的十五分钟一次的调度，调度做什么取决于 `foo_blah` 的定义。

应当怎么定义 `foo_blah` ，请参考帮助内容。

# 介绍

这是个工具。生成具体工具的工具。

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


### 折叠的形式

模板之所以能够变成目标工具，其实就是把模板代码中特定形式的字符串替换成特定的值。

在这里，最容易让人想到的就是用 `sed` 了，我可以用 `declare -f` 得到模板函数的定义内容，然后管道给编写好了特定规则的 `sed` 让它替换去。

——这是最容易想到的做法了。不过，这里我想先不管性能上的事情，整点儿不一样的。

——不如这样想！你看！用 `sed` 的话不就多依赖了别的软件了嘛！反正 `xargs` 是横竖都要用的，而且它也能做替换，那不如就用它试试看嘛！

所以，由于 `xargs -i` 就能达到我所需要的替换效果（而且好像最后做出的工具比 `sed` 看上去可以更直观），再加上这个工具本身也用到了 `xargs` ，所以就做了下面的事情……

*只要执行过 `: : defines &&` 到 `: : runs &&` 之间的，所有定义性质的命令了，并且对三个变量也直接赋值过了，那么这里（即 `: : runs &&` 以下）的代码就都可以在这个上下文中直接测试了。建议在你自己的 Bash 上亲自测测看效果。直接把代码复制上去就可以，随便哪一部分。（如果在最后还是总是得到 `> ` 的提示符，可以考虑输入 `:` 后回车。）*

*考虑到函数命名，这里需要的 SHell 不能是一般的 POSIX SHell 了。这里我用的是 `bash` 。*


#### 旧的整活记录（可跳过）

这是整的旧活。可以跳过，因为多了很多多余的部分。

亏我还能这样就整了下去。

首先：

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

写这个分析文档的时候，由于要分小部分地描述代码的意义是啥，我就发现了里面不必要的部分。

然后，就有了下面的正确的变化流程。

（感兴趣也可以比比旧的和新的的区别在哪……）



#### 新的抽象历史

分三步：

- 先用最朴素的办法去写（我会详细说说定义内容的替换阶段）
- 然后转换成管道的形式（把上一个方式用管道的形式来写）
- 然后再抽象（这里就会用到 `eval` 了）

下面我管这三步叫三种 *方式* 。

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

它的形成有三个阶段。一个阶段对应一次替换。

（就是在分析自己这仨阶段的时候我发现了上面的旧整活的有多余部分。。。）

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

如何？是不是比前面舒服多了？

（这或许也是 Elixir 受欢迎的原因吧……）

把前面的阶段对应一下就是这样子——

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

成了。

再为了统一以下结尾符形式，就最后再加个 ` | cat - ` 。

成了。

##### 方式 3 : 抽象

看看 *方式 2* ，是不是有两行代码非常像？只有一点不同？

这两行代码，是不是也能用 `xargs` 提供带 `{}` 的模板给生成出来？

既然能打印代码那么是不是就能执行代码？而且还是在当前上下文！

那么，使用 `eval` 就好了——

这便是结果：

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

嗯。

看起来，代码好像变多了。

可能是我认为有必要有的格式化所导致的。

不明白吗？

你可以试试看这个部分的执行效果：

~~~ sh
echo STEP_TIME_TYPE STEP_TIME_VALUE |
    
    xargs -n1 |
    xargs -i -- echo '
        
        (f="$(cat -)" && echo "${}" | xargs -i:..{}..: -- echo "$f") |'
~~~

是不是，印出来两行代码？这不就对了嘛！

既然是对的代码，丢给 `eval` 就好，最后加上一个 `cat -` 来结尾就好了。

接下来，得出它的抽象：

~~~ sh
History ()
{
    local log="${1}" && shift 1 &&
    local mod="${1}" && shift 1 &&
    
    echo "$@" | xargs -n1 | xargs -i"${mod}" -- echo "$log" &&
    :;
} ;
~~~

它的使用方式是：

~~~ sh
eval "$(History '(f="$(cat -)" && echo "${}" | xargs -i:..{}..: -- echo "$f") |' STEP_TIME_TYPE STEP_TIME_VALUE) cat -"
~~~

这个完全可以再封装一下嘛。

然后，就有了这个：

~~~ sh
historisch ()
{
    local head="${1}" && shift 1 &&
    local log="${1}" && shift 1 &&
    local tail="${1}" && shift 1 &&
    
    eval "$(History "$log" "$head" "$@") $tail" &&
    :;
} ;
~~~

它其实也可以写成这样：

~~~ sh
historisch ()
{
    eval "$(History 'local {}="${1}" && shift 1 &&' {} head log tail) :" &&
    eval "$(History "$log" "$head" "$@") $tail" &&
    :;
} ;
~~~

看，它完全只有在通过上面提到的使用方式使用 `History` 而已。

接下来，补上 `History` ，再加一些使用说明。完整的这俩东西就是这样了：

~~~~~ sh
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
~~~~~

这其中， `historisch` 其实可以认为是， `History` 的使用例。

而本生成工具的工具，就是这个 `historisch` 的使用例了。

最有意思的就是，经过上面一通抽象后， `historisch` 的定义中也体现了对 `History` 的使用的抽象的过程。

有了这个，核心部分就只需要这样写了：

~~~~ sh
(historisch '{}' 'declare -f -- :..{}..:_scheduler &&' : APP_NAME) |
    historisch '{}' '(f="$(cat -)" && echo "${}" | xargs -i:..{}..: -- echo "$f") | ' 'cat -' APP_NAME STEP_TIME_TYPE STEP_TIME_VALUE
~~~~

管道左边，把所有的模板打印，这里只有 `APP_NAME` 所在的模板。

管道之后，则是读取内容并做一次如代码所示规则的替换，这里因为后面是三个变量所以是三次替换，分别把这三个变量名模板位置替换成它们的值，这分别对应前面说的 *三个阶段* 。



