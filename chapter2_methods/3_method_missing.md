# method_missind()

`BasicObject#method_missing()`

method_missing()はプライベートだけど、send()を呼び出せばまぁ無理やり呼べるね。

```ruby
BasicObject.send :method_missing, :my_method
```


