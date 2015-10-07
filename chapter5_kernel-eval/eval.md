# Kernel#eval

## Kernel#evalの危険性

eval()メソッドはその自由度ゆえに、大きな危険が伴う。

例えば、みんなが使えるような場所でeval()を実行できるようにすると、

```
p ""; eval "Dir.glob("*")"
```

なんてされたらこちらの情報が全部抜き取られたりしてしまう。

このようなインジェクションを防ぐためには、evalは自分のコードだけを実行する
ように気をつける。


## フックメソッド

Rubyにはいろんなフックメソッドがある！

そしてオブジェクトモデルの重要なイベントはほとんど網羅されてる。
例えば...

* Class#inherited
* Module#included
* Module#extend_object
* Module#method_added
* method_removed
* method_undefined
* etc...
