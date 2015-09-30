**スコープゲート**...プログラムがスコープを切り替えて、アタrしいスコープをオープンする場所は3つあり、それを覚えておくことによって素早くスコープを特定できる

* クラス定義 `class`
* モジュール定義 `module`
* メソッド呼び出し `def`...メソッド定義のコードだけはメソッドを呼び出したときに実行されるため、スコープの変化するタイミングが違う。


### `class`を飛び越えてローカル変数を渡す方法

Class.new()がclassの置き換えになる。スコープゲートが開かない！

```ruby
my_var = "Success!"

MyClass = Class.new do
  puts "#{my_var}がクラス定義の中に！"
end
```

### `def`を飛び越えてローカル変数を渡す方法

```ruby
my_var = "Success!"

MyClass = Class.new do
  define_method :my_method do
    puts "#{my_var}はメソッド定義の中に！"
  end
end
```

このほうな方法は、**入れ子構造のレキシカルスコープ**と呼ばれ、Rubyistの中では
「スコープのフラット化」と呼ばれる。これが**フラットスコープ**という魔術である。

### 共有スコープ

define_methods()メソッドで囲むことで、任意のメソッドにだけ変数を共有できる。

```ruby
def define_methods
  shared = 0

  Kernel.send :define_method, :counter do
    shared
  end

  Kernel.send :define_method, :inc do |x|
    shared += x
  end
```
