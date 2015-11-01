module ActiveSupport
  # A typical module looks like this:
  #
  #   module M
  #     def self.included(base)
  #       base.extend ClassMethods
  #       base.class_eval do
  #         scope :disabled, -> { where(disabled: true) }
  #       end
  #     end
  #
  #     module ClassMethods
  #       ...
  #     end
  #   end
  #
  # By using <tt>ActiveSupport::Concern</tt> the above module could instead be
  # written as:
  #
  #   require 'active_support/concern'
  #
  #   module M
  #     extend ActiveSupport::Concern
  #
  #     included do
  #       scope :disabled, -> { where(disabled: true) }
  #     end
  #
  #     class_methods do
  #       ...
  #     end
  #   end
  #
  # Moreover, it gracefully handles module dependencies. Given a +Foo+ module
  # and a +Bar+ module which depends on the former, we would typically write the
  # following:
  #
  #   module Foo
  #     def self.included(base)
  #       base.class_eval do
  #         def self.method_injected_by_foo
  #           ...
  #         end
  #       end
  #     end
  #   end
  #
  #   module Bar
  #     def self.included(base)
  #       base.method_injected_by_foo
  #     end
  #   end
  #
  #   class Host
  #     include Foo # We need to include this dependency for Bar
  #     include Bar # Bar is the module that Host really needs
  #   end
  #
  # But why should +Host+ care about +Bar+'s dependencies, namely +Foo+? We
  # could try to hide these from +Host+ directly including +Foo+ in +Bar+:
  #
  #   module Bar
  #     include Foo
  #     def self.included(base)
  #       base.method_injected_by_foo
  #     end
  #   end
  #
  #   class Host
  #     include Bar
  #   end
  #
  # Unfortunately this won't work, since when +Foo+ is included, its <tt>base</tt>
  # is the +Bar+ module, not the +Host+ class. With <tt>ActiveSupport::Concern</tt>,
  # module dependencies are properly resolved:
  #
  #   require 'active_support/concern'
  #
  #   module Foo
  #     extend ActiveSupport::Concern
  #     included do
  #       def self.method_injected_by_foo
  #         ...
  #       end
  #     end
  #   end
  #
  #   module Bar
  #     extend ActiveSupport::Concern
  #     include Foo
  #
  #     included do
  #       self.method_injected_by_foo
  #     end
  #   end
  #
  #   class Host
  #     include Bar # It works, now Bar takes care of its dependencies
  #   end
  module Concern
    class MultipleIncludedBlocks < StandardError #:nodoc:
      def initialize
        super "Cannot define multiple 'included' blocks for a Concern"
      end
    end

    def self.extended(base) #:nodoc:
      # Concernクラスをextendしたモジュールは、クラス変数@_dependenciesを手に入れる
      base.instance_variable_set(:@_dependencies, [])
    end

    # concern(Conernクラスをextendしてるクラス)のクラスメソッドとして呼ばれる
    # selfはconcernである
    # baseはincludeしてるモジュールで、普通のモジュールかもしれないし、
    # あるいはconcernかもしれない
    def append_features(base)
      if base.instance_variable_defined?(:@_dependencies)
        # includeするクラスがconcernなら、
        # 依存関係のリストに自分自身(concern)を追加する
        base.instance_variable_get(:@_dependencies) << self
        # 継承チェーンに自身を追加していないこと
        # = includeが発生しなかったことを示すために、falseを返す
        # e.g. ActiveModel::ValidationsがActiveRecord::Validationsにインクルードされたとき
        return false
      else
        # e.g. こっちは、ActiveRecord::ValidationsがActiveRecord::Baseにインクルードされたとき
        # 継承チェーンにすでに自分自身が追加されてるならincludeしない
        return false if base < self
        # インクルーダーに依存関係を再帰的にincludeしていく
        # ここが「include連鎖」の問題を解決する
        @_dependencies.each { |dep| base.include(dep) }
        # Module#append_featuresを呼び出してもともとの処理
        # (=継承チェーンに自分自身を追加する)を行う
        super
        # Kernel#const_getでClassMethodsの参照で取得し、extendする
        base.extend const_get(:ClassMethods) if const_defined?(:ClassMethods)
        base.class_eval(&@_included_block) if instance_variable_defined?(:@_included_block)
      end
    end

    def included(base = nil, &block)
      if base.nil?
        raise MultipleIncludedBlocks if instance_variable_defined?(:@_included_block)

        @_included_block = block
      else
        super
      end
    end

    def class_methods(&class_methods_module_definition)
      mod = const_defined?(:ClassMethods, false) ?
        const_get(:ClassMethods) :
        const_set(:ClassMethods, Module.new)

      mod.module_eval(&class_methods_module_definition)
    end
  end
end
