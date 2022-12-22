
。。。其实没啥玄乎的。

就是用 `eval` 做了个对指定的一些内部定义的 `unset` 。

具体的使用例：

~~~~ bash
: first:

source childs-fun/src.bash


: then defile this:

lovers ()
{
    :;
    
    love ()
    {
        one: ()
        { echo 1 "$@" ; } &&
        
        two: ()
        { echo 2 "$@" ; } &&
        
        eval "$(erot innerfun bodies:  one: two:)" ;
    } &&
    
    kiss: ()
    {
        love two: mua "$@" ;
    } &&
    
    eval "$(erot innerfun bodies:  love kiss:)" ;
} ;



: then u can use like:

lovers love one: xxx xxxx
# will out: 1 xxx xxxx

lovers kiss: xxx xxxx
# will out: 2 mua xxx xxxx
~~~~

--------

然而其实甭这么麻烦。

直接像这样就行了：

~~~~ bash
lovers ()
{
    :;
    
    love ()
    {
        one: ()
        { echo 1 "$@" ; } &&
        
        two: ()
        { echo 2 "$@" ; } &&
        
        "$@"
    } &&
    
    kiss: ()
    {
        love two: mua "$@" ;
    } &&
    
    "$@"
} ;



: then u can use like:

(lovers love one: xxx xxxx)
# will out: 1 xxx xxxx

(lovers kiss: xxx xxxx)
# will out: 2 mua xxx xxxx
~~~~

无非是用的时候要加个括号罢了。

或者也可以写 `("$@")` ，但是没必要。

无非就是怕内部的定义被泄露到外面而已……用子进程就可以完美解决。

——当然，你要是不想开新的子进程，那自然还是可以用这个的。但记住，它就只是给你 `unset` 掉被指定的东西而已。

论优雅，我觉得不如子进程优雅。谁写个脚本还成天搞 `import` ？一种给功能类似于 `包` 的方案就足够了。

另外，子命令这个东西我是从 Go 学得。至于那个冒号，也可以在设计里剔除掉它，转而要求不要递进过深就好，这样也就符合 POSIX 的命名了。
