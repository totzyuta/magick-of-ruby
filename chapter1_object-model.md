# Chapter1 オブジェクトモデル

## オープンクラス　

オープンクラスを使うとき

- オブジェクト指向っぽくしたい。オブジェクト自身に処理させたい

でもでも...

- 標準クラスを汚すのはかなりリスキー
- 予期せぬ動作を引き起こしてしまうことも...

=> 特異メソッドを使おう(149)

Rubyに置ける`class`キーワードはスコープ演算子のようなもの！！！！「classを定義する」というより「classを再オープンする・そのclassのコンテキストに入る」ととらえた方が的確。

Rubyの標準クラスにメソッドを追加している例として、RubyMoney/moneyが挙げられている。

https://github.com/RubyMoney/money

標準クラスにメソッドを追加したりするような安易なパッチを**モンキーパッチ**と呼ぶ。モンキーパッチはクラスの名前空間を汚染する。(メソッド名が被ったら大変！なことになるかも...)

モンキーパッチの解決策 => セレクタネームスペース


### 1.3 クラスの真実

* `obj.class`: インスタンスのクラス名の取得
* `obj.instance_variables`: インスタンス変数の一覧を取得
* `obj.methods`: メソッドの一覧を取得


#### インスタンス変数について知るべきこと

* **インスタンス変数はオブジェクトに住んでいる**
* Javaなどの静的言語と違い、Rubyではオブジェクトのインスタンス変数はクラスと何のつながりもない
* インスタンス変数は値を代入したときに初めて出現するので、同じクラスのインスタンス同士でもインスタンス変数の数が違う場合もある
* 同じクラスのオブジェクトがインスタンス変数を共有しないのは、だからだよね！

 
#### メソッドについて知るべきこと

* **メソッドはクラスに住んでいる**
* オブジェクトが保持してるのは、せいぜいインスタンス変数と、クラスへの参照と、あと特別な状態を表す`tainted`とか`frozen`とかくらいだ
* 同じメソッドのことを、クラスに着目しているときは「インスタンスメソッド」、オブジェクトに着目しているときは「メソッド」と呼ぶ

```ruby
String.instance_methods == "abc".methods
```

#### クラスについて知るべきこと

* **クラスはオブジェクトである**
* 「オブジェクトのメソッドはクラスのインスタンスメソッド」＝「クラスのメソッドはClassクラスのインスタンスメソッド」

```ruby
pry> String.superclass
=> Object
pry> Object.superclass
=> BasicObject
pry> Basicobject.superclass
=> nil
```

>Ruby 1.8以前ではRubuのオブジェクト階層のルートはObjectだった。Ruby 1.9からObjectのスーパークラスにBasicobjectが追加された。Basicobjectが存在する理由を理解するには、102ページの補足まで待ってほしい。

* クラスは3つのメソッド( new(), allocate(), superclass() )を追加したモジュールだ！！！

```ruby
pry> Class.superclass
=> Module
pry> Module.superclass
=> Object
```

* クラスはオブジェクトで、クラス名は定数


#### 定数について知るべきこと

* 大文字で始まる参照は、クラス名やモジュール名も含めて全て定数

>Rubyの定数は、値を変更できるという意味では変数とよく似ている。ただし、定数に値を再代入するとインタプリタから警告を受ける。もし何か壊したい気分になったらStringクラスの名前を変更して、Rubyをぶっ壊すことだってできてしまう。

* プログラムにあるすべての定数はツリー状に並んでいる
* モジュールがディレクトリで、定数がファイルを表す

```ruby
module MyModule
  MyConstant = "External Constant"

  class MyClass
    Myconstant = "Internal Constant"
  end
end
```

このとき、以下のように定数を参照でき、MyModule::MyConstantとMyModule::MyClass::MyConstantは同じではない！

```
e.g. 
MyModule::MyConstant = "External Constant"
MyModule::MyClass::MyConstant = "Internal Constant"
```

`Module#constants`/`Module.constants`: 現在のスコープにあるすべての定数を返す。Module.constantsはトップレベルにあるすべての定数を返すことになるね。

`Module.nesting`: 現在のパスを返す

```ruby
module MyModule
  class MyClass
    Module.nesting
  end
ned

=> [MyModule::MyClass, MyModule]
```

そこより浅いレベルの定数は参照できるからパスが複数返ってくるのかな。

```ruby
module MyModule
  MyModuleConstant = "my module constant"
  class MyClass
    p MyModuleConstant
  end
end

=> "my module constant"
```


#### Rake

* Rakeは昔はTaskやFileTaskみたいなクラス名が定義されたけど、衝突を回避するためにRakeモジュールの中にクラスを定義している。

```ruby
module Rake
  class Task
    # ...
```

これにより、Rake::Taskになり名前が衝突しない。このようにRakeのような定数をまとめるだけのモジュールのことを**ネームスペース**という。

`load('motd.rb', true)`と第二引数でtrueを渡すと、無名モジュールを作成してそれをネームスペースとして使ってmotd.rbの定数を取り込む。そのあとに無名モジュールを廃棄するので定数名がかぶる心配がなくなる。

>load()はコードを実行するために使い、require()はライブラリを読み込むために使う


### 1.5 What happens when a method is called?


Rubyはメソッドを呼び出すときに、

1. メソッドを探索する
2. 実行する。このとき、`self`が必要になる。

の2つのことを必ず行っている。Rubyではこれらを理解することが非常に重要。


#### メソッド探索について

メソッドを探索する、ということを一言で表すと、

「**Rubyがレシーバのクラスに入り、メソッドを見つけるまで継承チェーンを上ること**」

ということ。

=> "One step to the right, then up"ルール

継承チェーンを調べるのにはancestors()メソッドが便利！

```ruby
MySubclass.ancestors # => [MySubclass, MyClass, Object, Kernel, BasicObject]
```

Kernelモジュールがこれに含まれている。

モジュールをクラスにincludeするときは、実はRubyはそのモジュールを無名クラス(インクルードクラス、プロキシクラスと呼ばれる)でラップして、継承チェーンに挿入する。includeするクラスの真上に挿入される。

(そしてこのインクルードクラスには、通常Rubyのコードからはアクセスできないようになってる。例えば、`superclass`メソッドはそんなクラスなんてありませんよ的な振る舞いをするようになっている。)

そして、`print`などのインスタンスメソッドを持っているKernelモジュールは、Objectクラスが実はincludeしている。 => 全てのオブジェクトの継承チェーンにKernelモジュールが入り込むことになる！常にオブジェクトの内部にいることになるんだ。

例えば`gem`。

`gems/rubygems-update-1.3.3/rubygems.rb`で以下のように定義されている。


```ruby
module Kernel
  def gem(gem_name, *version_requirements)
# ...
```

なので、いきなり

```ruby
gem "rails"
```

とかできるんだ！



#### selfについて

self...カレントオブジェクト。メソッドを呼び出すときには、レシーバがselfになる。

=> 「**Rubyの達人になりたいなら、常に`self`のオブジェクトを意識しなければならない**」

selfを探すには...最後にメソッドのレシーバとなったオブジェクトを追いかければよい、簡単だ。

注意: トップレベルのとき


```
self # => main
self.class # => Object
```

トップレベルコンテキストのとき、selfはRubyのインタプリタがつくったmainというオブジェクトであり、mainオブジェクトの内部にいることになる。


##### privateの本当の意味

プライベートメソッドって、実は「**暗黙的なレシーバselfに対するものでなければならない**」ってだけなんだ(!!)

self以外がレシーバになるオブジェクトはダメだし、self.privatemethodって、selfをつけてもダメ！（後者の場合selfを削除すればエラーは解消される）

```ruby
class C
  def public_method
    self.private_method
  end

  private

  def private_method; end
```

