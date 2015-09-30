# instance_eval()

## カプセル化の破壊

BasicObject#instance_evalは、渡されたブロックを、レシーバのオブジェクトの
元で実行する。ゆえに、そのオブジェクトのインスタンス変数にも外側から
アクセスできてしまう。

このブロックのことを、オブジェクトに落下させてそこで何かをするようすが
宇宙探索機に似ていることから**コンテキスト探索機**と呼ばれる。

instance_evalはカプセル化を破壊する。これは一見わるいことのように思えるが、
irbでさっとオブジェクトの中身をみたいときとか、あと正当なのはテスティングでの
使い方だ。

これが、スタブ。スタブはinstance_eval()によってカプセル化を破壊することによって
実現されている！

また、ブロックを評価するためだけにオブジェクトを生成することがある。
このようなオブジェクトは**クリーンルーム**と呼ばれる。


## 呼び出し可能オブジェクト

ブロックの使用方法は2段階。コードを保管し、yieldで実行する。

コードを保管できる場所は、少なくとも3通り考えられる。

* Procのなか。ブロックがオブジェクトになったもの
* lambdaのなか。Procの変形
* メソッドの中


### Procオブジェクト

Procオブジェクトは以下のように使用できる。

```ruby
inc = Proc.new {|x| x + 1 }
# ...
inc.call(2) # => 3
```

この方法は**遅延評価**と呼ばれる。

また、RubyはブロックをProcに変換する2つのカーネルメソッドも提供している。
これが、lambda()とproc()である。


#### lambda()とproc()とProc.newの違い

```ruby
dec = lambda {|x| x - 1 }
# ...
dec.class # => Proc
dec.call(2) # => 1
```

#### proc2ブロック

「このProcはブロックだよ」と教えてあげるには、`&`をつければよい。
そうすることで、yieldでブロックを呼び出すことができる。

```ruby
def my_method(greeting)
  puts "#{greeting}, #{yield}!"
end

my_proc = proc { "Bill" }
my_method("Hello", &my_method)
```

#### lambdaとProc

lambdaとProcは微妙に違う。

lambdaでは、returnは単にlambdaから戻るだけだが、Procでは、Procから
戻るのではなく、Procが定義されたスコープから戻るのである。

これは、**メソッドとlambdaでは、returnは呼び出し可能オブジェクトから戻るが、
Procとブロックでは呼び出し可能オブジェクトのコンテキストから戻る**と言える。


```ruby
# lambda
def double(callable_object)
  callable_object.call * 2
end

l = lambda { return 10 }
double(1) # => 20
```

```ruby
# Proc
def another_double
  p = Proc.new { return 10 }
  result = p.call
  return result * 2 # ここまでこない！
```


もうひとつ、項数に関する違いもあるけど、一旦割愛。

一般的に、lambdaの方がメソッドに似ていて、Procよりも直感的なので、Procの
機能が必要でない限りlambdaを使うRubyistが多い。


#### 矢印ラムダ

Ruby 1.9からはlamdbaを定義する新しい方法、矢印ラムダが導入された。

```ruby
p = ->(x) { x + 1 } # p = lambda {|x| x + 1 }
p.call 2 # => 3
```

#### Methodオブジェクト

Methodオブジェクトは、lambdaに似ているが、決定的な違いがある。
それは、lambdaは定義されたスコープ内で評価される(クロージャだね)が、Methodオブジェクトは属するオブジェクトのスコープで評価される。

```ruby
class MyClass
  def initialize(value)
    @x = value
  end
  
  def my_method
    @x
  end
end
```

```ruby
object = MyClass.new(1)
m = object.method :my_method
m.call # => 1
```
