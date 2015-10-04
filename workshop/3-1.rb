class Bank
  def initialize(money, name)
    @money = money
    @name = name
  end

  private

  def own_bank
    p "#{@name}の講座です"
  end
end

yamaken_bank = Bank.new(2000, "山本健太")

yamaken_bank.instance_eval do
  @money = 1000 * 0.5
  @debt = 10000
  own_bank
end

p yamaken_bank
