# meta-shells

一些基于 `eval` 的 SHell 工具……或者方案。

- `childs-fun` ：
  
  这是一个子命令方案，你也可以把它当作一种模块化地规整代码的方案。
  
- `dialec-cmdline` ：
  
  这是一个交互功能。给命令指定问题与如何处理回答的逻辑，它就能工作。原理就是用 `eval` 让传入的字符串作为代码的片段运行起来。
  
- `history_machines`
  
  主要就是大概做了个「对管道 Fold 」这样的事情。以及介绍了一下怎么整出来的这么个玩意儿。
  
  这个应该有点一般语言里头动态宏的意思了。

--------

*这些目前只是玩具。 :P*
