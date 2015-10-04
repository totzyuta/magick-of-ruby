val = "success"

Hoge = Class.new do
  define_method :fuga do
    p val
  end
end

obj = Hoge.new
obj.fuga
