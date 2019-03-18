# AHKNMS
主要是觉得为上b碗下模型建个github账号实在是太zz了，所以就放点东西在上面好了<br><br>
主要就是一个可以解析数字谱的东西，会把一个标准的数字谱转换成一个如下的列表<br>

```autohotkey
    [["音高"， "音区", "时值"], ......]
```

初步打算实现一个转调器的功能，并写一个简陋的UI

### ver 0.0.1

1. 加入了 main.ahk 和 paser.ahk <br>
2. 大概把 parser.ahk 写完了，还没有测试过

### ver 0.0.2

1. 修了下 parser.ahk ，还没有测试过解析功能
2. 让 main.ahk 有个Gui的 helloworld 了

### ver 0.0.3

1. parser.ahk 终于可以正确解析了，是我太菜了

### ver 0.0.4

1. parser.ahk 可以解析临时升降号了
2. parser 现在会将音高解析成12平均律的12个半音
