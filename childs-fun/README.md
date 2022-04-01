这个函数用于支持子函数

使用例在其定义中已经得到体现

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

