# ミミックメソッドとは何か

ミミックメソッドとは、**メソッドが擬態した属性**のこと。

例えば、

```ruby
class C
  def my_attribute=(value)
    @p = value
  end
  
  def my_attribute
    @p
  end
end
```

上のようにメソッドを定義することで、以下のようなメソッドが使えるようになる。


```ruby
obj = C.new
obj.my_attribute = "Coffee"
obj.my_attribute # => "Coffee"
```

これは一見メソッドには見えない！

特に他の言語から入っている場合は、なるほどこれは属性だなぁぁと思ってしまう。これが、ミミック(擬態)メソッドと呼ばれる理由とのこと。

`attr_reader()`や`private()`や`protected()`などのアクセス修飾子さえも、ミミックメソッドだ。

例えば、`attr_reader()`は単純に上のような二つのメソッドを生成しているにすぎない。Rubyは、初めて見た時それが予約語に見えることがめちゃくちゃ不思議。



# TODO: search it


## ミミックメソッドの問題点

ミミックメソッドにはひとつ重要な問題点がある。例えば以下のようなコード。


```ruby
class MyClass
  attr_accessor :my_attr
  
  def initialize_attributes
    my_attr = 10
  end
end
```

これをおそらく書いた人が意図したように動かすと、以下のようにnilが帰ってくる。

```ruby
obj = MyClass.new
obj.initialize_attributes
obj.my_attr # => nil
```

ここで重要なのは、意図したように動かないことではない。

`my_attr = 10`がローカル変数への値の代入(`Numeric#+ `)なのか、my_attrのミミックメソッド`my_attr=-()`を呼び出しているのか判断することがないということだ。

Rubyは、迷ったら前者を優先する。ローカル変数への代入の方が優先度が高いということだ。

ここで疑問が残る。本当にそう？メソッド探索のルールでいうと、後者の方が優先度がたかそうなように思える。


