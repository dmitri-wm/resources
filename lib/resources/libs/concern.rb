module Concern
  class MultipleIncludedBlocks < StandardError # :nodoc:
    def initialize
      super "Cannot define multiple 'included' blocks for a Concern"
    end
  end

  class MultiplePrependBlocks < StandardError # :nodoc:
    def initialize
      super "Cannot define multiple 'prepended' blocks for a Concern"
    end
  end

  def self.extended(base) # :nodoc:
    base.instance_variable_set(:@_dependencies, [])
  end

  def append_features(base) # :nodoc:
    if base.instance_variable_defined?(:@_dependencies)
      base.instance_variable_get(:@_dependencies) << self
      false
    else
      return false if base < self

      @_dependencies.each { |dep| base.include(dep) }
      super
      base.extend const_get(:ClassMethods) if const_defined?(:ClassMethods)
      base.class_eval(&@_included_block) if instance_variable_defined?(:@_included_block)
    end
  end

  def prepend_features(base) # :nodoc:
    if base.instance_variable_defined?(:@_dependencies)
      base.instance_variable_get(:@_dependencies).unshift self
      false
    else
      return false if base < self

      @_dependencies.each { |dep| base.prepend(dep) }
      super
      base.singleton_class.prepend const_get(:ClassMethods) if const_defined?(:ClassMethods)
      base.class_eval(&@_prepended_block) if instance_variable_defined?(:@_prepended_block)
    end
  end

  # Evaluate given block in context of base class,
  # so that you can write class macros here.
  # When you define more than one +included+ block, it raises an exception.
  def included(base = nil, &block)
    if base.nil?
      if instance_variable_defined?(:@_included_block)
        raise MultipleIncludedBlocks if @_included_block.source_location != block.source_location
      else
        @_included_block = block
      end
    else
      super
    end
  end

  # Evaluate given block in context of base class,
  # so that you can write class macros here.
  # When you define more than one +prepended+ block, it raises an exception.
  def prepended(base = nil, &block)
    if base.nil?
      if instance_variable_defined?(:@_prepended_block)
        raise MultiplePrependBlocks if @_prepended_block.source_location != block.source_location
      else
        @_prepended_block = block
      end
    else
      super
    end
  end

  # Define class methods from given block.
  # You can define private class methods as well.
  #
  #   module Example
  #     extend ActiveSupport::Concern
  #
  #     class_methods do
  #       def foo; puts 'foo'; end
  #
  #       private
  #         def bar; puts 'bar'; end
  #     end
  #   end
  #
  #   class Buzz
  #     include Example
  #   end
  #
  #   Buzz.foo # => "foo"
  #   Buzz.bar # => private method 'bar' called for Buzz:Class(NoMethodError)
  def class_methods(&class_methods_module_definition)
    mod = if const_defined?(:ClassMethods, false)
            const_get(:ClassMethods)
          else
            const_set(:ClassMethods, Module.new)
          end

    mod.module_eval(&class_methods_module_definition)
  end
end