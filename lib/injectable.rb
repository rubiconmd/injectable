require 'injectable/version'
require 'injectable/class_methods'
require 'injectable/dependencies_graph'
require 'injectable/dependencies_proxy'
require 'injectable/dependency'
require 'injectable/instance_methods'
require 'injectable/missing_dependencies_exception'

module Injectable
  class Error < StandardError; end

  def self.included(base)
    base.extend(Injectable::ClassMethods)
    base.prepend(Injectable::InstanceMethods)
  end
end
