require "active_support"

module IncludedClass
  extend ActiveSupport::Concern

  def an_instance_method; "instance method"; end

  module ClassMethods
    def a_class_method; "class method"; end
  end
end

class BaseClass
  include IncludedClass
end

BaseClass.new.an_instance_method
BaseClass.a_class_method
