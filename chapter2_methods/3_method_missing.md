# method_missind()

`BasicObject#method_missing()`

method_missing()はプライベートだけど、send()を呼び出せばまぁ無理やり呼べるね。

```ruby
BasicObject.send :method_missing, :my_method
```


## Override method_missing()

method_missing()をoverrideすると、実際には存在しないメソッド、**ゴーストメソッド**を呼び出せます。


```ruby
class Barista
  def method_missing(method, *args)
    puts "#{method}(#{args.join(', ')})を呼び出しました！"
  end
end
```

```ruby
tim = Barista.new
tim.brew

=>  brew(kenya)を呼び出しました！
```


### ruportの例

ruportという、データから表形式の出力を得るためのgemがある。

ruportでは、`rows_with_xxx()`ってメソッドを用いてデータを各データを取り出したり、
例えば`to_csv`みたいに`to_xxx()`って形でデータを取り出せる。

`xxx`の部分ってユーザが登録したデータになるわけだったり、データ型だったりするわけ
だけど、ruportは最初からその全部を知ってるの？答えはもちろんNO.

以下のようにすることで、それぞれ`rows_with(:xxx)`、`as(:xxx)`みたいな
メソッド呼び出しに置き換えられるんだ！

```
class Table
  def method_missing(id, *args, &block)
    return as($1.to_sym, *args, &block) if id.to_s =~ /^to_(.*)/
    return rows_with($1.to_sym => args[0]) if id.to_s =~ /^rows_with_(.*)/
    super
  end
end
```

そしてメソッド名のプレフィックス(正規表現でマッチしてるかどうか調べてるとこ)に
マッチしなければ、superを呼ぶことになっている。superが呼ばれると、もともとの
method_missing()を呼び出して、NoMethodErrorを発生する(メソッドの探索を再開する)


### OpenStruct

Rubyの標準ライブラリにあるOpenStructオブジェクトはめちゃくちゃ面白い。
OpenStructオブジェクトの属性は、Rubyの変数のように扱える。
新しい属性(インスタンス変数かな？)が欲しい時は値を代入するだけで、
その属性が存在し始める！

```
icecream = MyOpenStruct.new
icecream.flavor = "strawberry"
icecream.flavor
```

```ruby
class MyOpenStruct
  def initialize
    @attributes = {}
  end
  
  def method_missing(name, *args)
    attributes = name.to_s
    if attribute =~ /=$/
      @attributes[attribute.chop] = args[0]
    else
      @attributes[attribute]
    end
  end
end
```

>method_missing()にメソッド呼び出しを集中させて、ラップしたオブジェクトに転送する。

オブジェクトがゴーストメソッドを受け取り、なんらかのロジック(メソッド名のプレフィックス以降を切り出して引数に渡すとか)を適用してから、他のオブジェクトに転送する。

これを**動的プロキシ**という。

では、Computerクラスをリファクタリングしてみる。

```ruby
class Computer
  def initialize(computer_id, data_source)
    @id = computer_id
    @data_source = data_source
  end
end

  def method_missing(name, *args)
    super if !@data_source.respond_to?("get_#{name}_info")
    info = @data_source.send("get_#{name}_info", args[0])
    price = @data_source.send("get_#{name}_price", args[0])
    result = "#{name.to_s.capitalize}: #{info} ($#{price})"
    return "* #{result}" if price >= 100
    result
  end
end
```

## method_missing()の二つの罠

### 無限ループ

method_missing()が定義されていることにより、method_missing()内のブロックで
定義されていないメソッド呼び出された(つまりmethod_missingが呼ばれる)ときに、
さらにmethod_missing()が呼ばれるという無限ループが起こってしまう...！


### 標準メソッド

メソッドが定義がかぶってしまった場合、method_missing()までたどり着かないので、
不意に予想もつかない挙動をしてしまうことがある。

このとき、

* Module#undef_method()で継承したメソッドも含めすべてのメソッドを削除する
* Module#remove_method()でレシーバのメソッドは削除するが、継承したメソッドはそのまま


### おまけ: パフォーマンス

Ghost methodは、その分探索時間が長くなるので実行処理時間も長くなる。
約2倍くらい違うこともあるそう。


