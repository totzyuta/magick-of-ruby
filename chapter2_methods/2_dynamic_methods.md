# Chapter2 メソッド

* **動的ディスパッチ**: `send()`を利用することでコードの実行時に呼び出すメソッドを決める書き方のこと。

* campingの例

YAMLファイルはパースされなと分からないので、設定コードを後から生成する、

```ruby
# gems/camping-1.5/bin/camping
# Load configuration if any
if conf.rc and File.exists?( conf.rc )
  YAML.load_file(conf.rc).each do |k,v|
    conf.send("#{k}", v)
  end
end
```

これでこんな感じのができちゃう！

```
conf.admin = "Bill"
conf.title = "Rubyland"
# ...
```

カッコイイね！

Test::Unitはファイル名に従ってメソッドを振り分ける。

```ruby
method_names = public_instance_methods(true)
tests = method_names.delete_if {|method_name| method_name !~ /^test./}
```

>スパイダーマンの叔父のことば

>「大きなる力には、大いなる責任が伴う。」

>Ruby 1.9では、`send()`の恐ろしさゆえにその挙動の変更が試みられたことがあった。しかしRuby 1.9.1現在では新しい、レシーバのプライバシーを尊重する`public_send()`が定義されるににとどまった。`send()`はどんなメソッドも呼び出せる(ということはプライベートなメソッドも！)がゆえに、意図せずにカプセル化を破壊してしまうメソッドだ、としてるRubyistもいるみたいだ。


### メソッドを動的に定義する

`Module#define_method()`にメソッド名とブロックを渡せばその場でメソッドを定義できる。

```ruby
class MyClass
  define_method :my_method do |my_arg|
    my_arg * 3
  end
end
```

これで、MyClassのインスタンスメソッドとして`my_method()`が定義された。`MyClass#my_method`


```ruby 
obj = MyClass.new
obj.my_method(2) # => 6
```

実行時にメソッドを定義する技術は**動的メソッド**と呼ばれる。


### リファクタリング

ここはめっちゃくっちゃあつい！！！再読必須。

まずはじめに、最初の重複だらけだったコードがある程度リファクタリングされたところから示す。


```ruby
class Computer
  def initialize(computer_id, data_source)
    @id = conputer_id
    @data_source = data_source
  end

  def self.define_component(name)
    define_method(name) {
      info = @data_source.send "get_#{name}_info", @id
      price = @data_source.send "get_#{name}_price", @id
      result = "#{name.to_s.capitalize}: #{info} ($#{price})"
      return "* #{result}" if price >= 100
      result
    }
  end

  define_component :mouse
  define_component :cpu
  define_component :keyboard
end
```

これでも十分キレイになった。でもまだRubyはイケる。


```ruby
class Computer 
  def initialize(computer_id, data_source)
    @id = computer_id
    @data_source = data_source
    data_source.method.grep(/^get_(.*)_info$/) { computer.define_component $1 }
  end

  def self.define_component(name)
    define_method(name) {
      info = @data_source.send "get_#{name}_info", @id
      price = @data_source.send "get_#{name}_price", @id
      result= "#{name.capitalize}: #{info} ($#{price})"
      return "* {result}" if price >= 100
      result
    }
  end
end
```

```
my_computer = Computer.new(42, DS.new)
my_computer.cpu # => * CPU: 2.16 Ghz ($220)
```

Computerクラスのインスタンスが生成されると、`String#grep`メソッドが呼び出される。
`String#grep`にブロックを渡すと、ブロックは正規表現にマッチした要素全てに対して評価される。

なので、`get_cpu_info`とかのメソッドがあるたびに、define_componentが呼び出されるってわけ。

そしてdefine_componentは、`send()`を使った動的ディスパッチにより、もらってきた引数によってメソッドを実行し分けるような、メソッドを動的メソッド的に定義している。

これの素晴らしいところは、新しい種類のDSが入ってきてもコードを追加する必要がないってことだ！！それは全部Rubyがやってくれる！まさに魔術だ...笑

あとはclassの定義中ではselfはクラス自身になっているので、ここではselfがdefine_componentのレシーバになるってことにも注意ね！！

