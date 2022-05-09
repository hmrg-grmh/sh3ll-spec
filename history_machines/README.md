在 `historisch` 里有 `History` 的定义。其中前者也是后者的使用例。

## 功能演示

### 历史 `History`

`History 'local {}="$1" && shift 1 &&' '{}' K1 K2` ：

它只会丢给标准输出这样的一些字符串：

~~~ text
local K1="$1" && shift 1 &&
local K2="$1" && shift 1 &&
~~~

要想在当前上下文应用这些代码就要写成 `eval "$(History 'local {}="$1" && shift 1 &&' '{}' K1 K2) :"` ，这相当于——

~~~ sh
local K1="$1" && shift 1 &&
local K2="$1" && shift 1 && :
~~~

相当于这样的代码在 `eval` 的位置执行。

### 历史性 `historisch`

***历史性 `historisch` 其实也算是历史 `History` 的使用例，或者说，一般使用的抽象（封装）；同时，历史性 `historisch` 的定义也不可避免地成为了它本身这么个抽象的得出过程的演示。***

如果执行 `historisch {} 'local {}="$1" && shift 1 &&' : K1 K2` 的话：

效果就等同于执行 `eval "$(History 'local {}="$1" && shift 1 &&' '{}' K1 K2) :"` 了。

也就等同于，在**这个代码的位置**在**当前进程的上下文**执行这个：

~~~ sh
local K1="$1" && shift 1 &&
local K2="$1" && shift 1 && :
~~~

别的以此类推。

## 使用案例

这是对 `historisch` 的使用：

- [`perday_scheduler_maker`](perday_scheduler_maker)
- [`para_tester`](para_tester)

