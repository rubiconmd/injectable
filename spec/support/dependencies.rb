DepWithNormalArg = Class.new do
  attr_reader :somearg
  def initialize(somearg)
    @somearg = somearg
  end
end

DepWithKwargs = Class.new do
  attr_reader :somearg
  def initialize(somearg:)
    @somearg = somearg
  end
end

DepWithBothArgs = Class.new do
  attr_reader :somearg, :options
  def initialize(somearg, **options)
    @options = options
    @somearg = somearg
  end

  def to_s
    "#{options[:my_arg]} | #{somearg}"
  end
end

DepWithManyArgs = Class.new do
  def initialize(arg1 = nil, arg2 = nil, arg3: nil, arg4: nil)
    @args = [arg1, arg2, arg3, arg4]
  end

  def call
    @args
  end
end

SomeRenderer = Class.new do
  def render(arg, kwarg:)
    "#render has been called with #{arg} and #{kwarg}"
  end
end

SomeCallableRenderer = Class.new do
  def render(arg, kwarg:)
    "#render has been called with #{arg} and #{kwarg}"
  end

  def call(something_else)
    "#call with #{something_else}"
  end
end

Chicharrons = Class.new

ExistingClass = Class.new do
  def call
    'This has been constantized!'
  end
end

WeirdName = Class.new do
  def call
    'This has been constantized!'
  end
end

InjectedDep = Class.new do
  def call
    'InjectedDep result'
  end
end

InjectedClass = Class.new do
  include Injectable

  dependency :injected_dep

  def call
    "I got #{injected_dep.call}"
  end
end

class Counter
  def initialize
    @count = 0
  end

  def count
    @count += 1
  end
end

class Somedep
  include Injectable

  dependency :counter

  def call
    "Somedep -> #{counter.count}"
  end
end

class OverridenCounter
  def count
    "Overriden!"
  end
end

class Anotherdep
  include Injectable

  dependency :counter

  def call
    "Anotherdep -> #{counter.count}"
  end
end

class BlockyClass
  include Injectable

  dependency :needed do
    'this is needed'
  end

  dependency :needer, depends_on: :needed do |needed:|
    "I got '#{needed}'"
  end

  def call
    needer
  end
end

class CallableBlockPasser
  def call
    yield
  end
end

class RunnableBlockPasser
  def run
    yield
  end
end

class Parent
  class Dependency
    def call
      'in parent'
    end
  end

  include Injectable
  extend Forwardable
  dependency :dependency
  def_delegators :dependency, :call
end

class Child < Parent
  class Dependency
    def call
      'in child'
    end
  end
end

class Sibling < Parent
  class Dependency
    def call
      'in sibling'
    end
  end
end
