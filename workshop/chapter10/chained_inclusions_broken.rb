module SecondLevelModule
  def self.included(base)
    base.extend ClassMethods
  end

  def second_level_instance_method; "ok"; end

  module ClassMethods
    def second_level_class_method; "ok"; end
  end
end


module FirstLevelModule
  def self.included(base)
    base.extend ClassMethods
  end

  def first_level_instance_method; "ok"; end

  module ClassMethods
    def first_level_class_method; "ok"; end
  end

  include SecondLevelModule
end


class BaseClass
  include FirstLevelModule
end
