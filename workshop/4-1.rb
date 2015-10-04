# def hoge(a, b, block)
#   yield(a, b)
# end
# 
# hoge(10, 20){ |a, b| p a * b }

def block2proc(a, b, &block)
  block
end

obj = block2proc(10, 20) { "test" }
