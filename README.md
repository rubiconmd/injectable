# Injectable

[![Maintainability](https://api.codeclimate.com/v1/badges/a45cc5935a5c16b837ed/maintainability)](https://codeclimate.com/github/rubiconmd/injectable/maintainability)![Ruby](https://github.com/rubiconmd/injectable/workflows/Ruby/badge.svg)

`Injectable` is an opinionated and declarative [Dependency Injection](https://en.wikipedia.org/wiki/Dependency_injection) library for ruby.

It is being used in production (under ruby 3.1) in [RubiconMD](https://github.com/rubiconmd) and was extracted from its codebase.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'injectable', '>= 1.0.0'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install injectable

## Motivation

The main motivation of `Injectable` is to ease compliance with [SOLID's](https://en.wikipedia.org/wiki/SOLID)\*, [SRP](https://en.wikipedia.org/wiki/Single_responsibility_principle)\* and [Dependency Inversion principle](https://en.wikipedia.org/wiki/Dependency_inversion_principle) by providing a declarative and very readable [DSL](https://en.wikipedia.org/wiki/Domain-specific_language)\* which avoids lots of bolierplate code and thus encourages good practices.*

*Sorry about the acronyms, but using an [Ubiquitous Language](https://martinfowler.com/bliki/UbiquitousLanguage.html) is important.

### Encapsulate domain logic

Using Ruby on Rails recommended practices as an example, when your application grows enough you usually end up with huge model classes with too many responsibilities.

It's way better (although it requires effort and discipline) to split those models and extract domain logic into [Service Objects](https://martinfowler.com/bliki/AnemicDomainModel.html) ("SOs" from now on). You can do this without `Injectable`, but `Injectable` will make your SOs way more readable and a pleasure not only to write but also to test, while encouraging general good practices.

### Avoiding to hardcode dependencies

If you find occurences of `SomeClass.any_instance.expects(:method)` in your **unit** tests, then you are probably hardcoding dependencies:

```rb
test "MyClass#call"
  Collaborator.any_instance.expects(:submit!) # hardcoded dependency
  MyClass.new.call
end

class MyClass
  attr_reader :collaborator

  def initialize
    @collaborator = Collaborator.new
  end

  def call
    collaborator.submit!
  end
end
```

What if you did this instead:

```rb
test "MyClass#call"
  collaborator = stub('Collaborator')
  collaborator.expects(:submit!)
  MyClass.new(collaborator: collaborator).call
end

class MyClass
  attr_reader :collaborator

  def initialize(collaborator: Collaborator.new) # we will just provide a default
    @collaborator = collaborator
  end

  def call
    collaborator.submit!
  end
end
```

The benefits are not only for testing, as now your class is more modular and you can swap collaborators as long as they have the proper interface, in this case they have to `respond_to :submit!`

`Injectable` allows you to write the above code like this:

```rb
class MyClass
  include Injectable

  dependency :collaborator

  def call
    collaborator.submit!
  end
end
```

It might not seem a lot but:

1. Imagine that you have 4 dependencies. That's a lot of boilerplate.
2. `Injectable` is not only this, it has many more features. Please keep reading.

## Usage example

`Injectable` is a mixin that you have to include in your class and it will provide several macros.

This is a real world example:

```rb
class PdfGenerator
  include Injectable

  dependency :wicked_pdf

  argument :html
  argument :render_footer, default: false

  def call
    wicked_pdf.pdf_from_string(html, options)
  end

  private

  def options
    return {} unless render_footer

    {
      footer: {
        left: footer,
      }
    }
  end

  def footer
    "Copyright ® #{Time.current.year}"
  end
end

# And you would use it like this:
PdfGenerator.call(html: '<some html here>')
# Overriding the wicked_pdf dependency:
PdfGenerator.new(wicked_pdf: wicked_pdf_replacement).call(html: '<some html>')
```

## Premises

In order to understand how (and why) `Injectable` works, you need to know some principles.

### #1 The `#call` method

`Injectable` classes **must define a public `#call` method that takes no arguments**.

This is **the only public method** you will be defining in your `Injectable` classes.

```rb
# Correct ✅
def call
  # do stuff
end

# Wrong ❗️
def call(some_argument)
  # won't work and will raise an exception at runtime
end
```

If you want your `#call` method to receive arguments, that's what the `#argument` macro is for. BTW, we call those **runtime arguments**.

Why `#call`?

Because it's a ruby idiom. Many things in ruby are `callable`, like lambdas.

### #2 The `initialize` method

Injectable classes take their **dependencies as keyword arguments** on the `initialize` method. They can also take **configuration arguments** on `initialize`:

```rb
MyClass.new(some_dep: some_dep_instance, some_config: true).call
```

`Injectable` instantiates **dependencies that you have declared with the `dependency` macro** for you and passes them to `initialize`, so if you don't want to override those you don't even need to instantiate the class and you can use the provided class method **`#call` shortcut**:

```rb
Myclass.call # This is calling `initialize` under the hood
```

If you need to override dependencies or configuration options, just call `new` yourself:

```rb
Myclass.new(some_dep: Override.new, some_config: false).call
```

If you do that, **any dependency that you didn't pass will be injected by `Injectable`**.
Notice that **configuration arguments**, which are declared with `#initialize_with` behave in the exact same way.

### #3 Keyword arguments

Both `#initialize` and `#call` take **keyword arguments**.

### #4 Readers

All `Injectable` macros define reader methods for you, that's why you define `#call` without arguments, because **you access everything you declare via reader methods**.

## The `#dependency` macro

This is the main reason why you want to use this library in the first place.

There are several ways of declaring a `#dependency`:

### Bare dependency name

```rb
class ReportPdfRenderer
  include Injectable

  dependency :some_dependency
end
```

1. `Injectable` first tries to find the `SomeDependency` constant in `ReportPdfRenderer`namespace.
2. If it doesn't find it, then tries without namespace (`::SomeDependency`).

Notice that this happens **at runtime**, not when defining your class.

### Explicit, inline class:

```rb
class MyInjectable
  include Injectable

  dependency :client, class: Aws::S3::Client
  dependency :parser, class: VeryLongClassNameForMyParser
end
```

Nothing fancy here, you are explicitly telling `Injectable` which class to instantiate for you.

You will want to use this style for example if the class is namespaced somewhere else or if you want a different name other than the class', like for example if it's too long.

Notice that this approach sets the class when ruby interprets the class, **not at runtime**.

### With a block:

```rb
dependency :complex_client do
  instance = ThirdPartyLib.new(:foo, bar: 'goo')
  instance.set_config(:name, 'value')
  instance
end
```

It's important to understand that `Injectable` won't call `#new` on whatever you return from this block.

You probably want to use this when your dependency has a complex setup. We use it a lot when wrapping third party libraries which aren't reused elsewhere.

If you want to wrap a third party library and you need to reuse it, then we recommend that you write a specific `Injectable` class for it, so it adheres to its principles and is easier to use.

### `#dependency` options

#### `:with`

If the dependency takes arguments, you can set them with :with

```rb
# Arrays will be splatted: WithNormalArguments.new(1, 2, 3)
dependency :with_normal_arguments, with: [1, 2, 3]
# Hashes will be passed as-is: WithKeywordArguments.new(foo: 'bar)
dependency :with_keyword_arguments, with: { foo: 'bar' }
```

### `:depends_on`

It allows you to share **memoized instances** of dependencies and supports both a single dependency or multiples as an Array:

```rb
dependency :client # this will be instantiated just once and will be shared
dependency :reporter, depends_on: :client
dependency :mailer,   depends_on: %i[client reporter]
```

Dependencies of dependencies will be passed as keyword arguments using the same name they were declared with. In the example above, `Injectable` will instantiate a `Mailer` class passing `{ client: client, reporter: reporter }` to `#initialize`.

If you have a dependency that is defined with a block which also depends_on other dependencies, you'll receive those as keyword arguments:

```rb
dependency :my_dependency, depends_on: :client do |client:|
  MyDependency.new(client)
end
```

### `:call`

Sometimes you have a class that doesn't adhere to `Injectable` principles:

```rb
dependency :renderer

def call
  renderer.render # this class does not respond to `call`
end
```

`:call` is a way of wrapping such dependency so it behaves like an `Injectable`:

```rb
dependency :renderer, call: :render

def call
  renderer.call
end
```

It's important to understand that **you can mix and match all dependency configurations and options** described above.

## `#initialize_with` macro

This macro is meant for **configuration arguments** passed to `initialize`:

```rb
initialize_with :debug, default: false
```

If you don't pass the `:default` option the argument will be required.

## `#argument` macro

`#argument` allows you to define **runtime arguments** passed to `#call`

```rb
argument :browser, default: 'Unknown'
```

If you don't pass the `:default` option the argument will be required.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Please consider configuring [https://editorconfig.org/] on your favourite IDE/editor, so basic file formatting is consistent and avoids cross-platform issues. Some editors require [a plugin](https://editorconfig.org/#download), meanwhile others have it [pre-installed](https://editorconfig.org/#pre-installed).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rubiconmd/injectable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Injectable project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Credits

- [RubiconMD](https://github.com/rubiconmd) allowed extracting this gem from its codebase and release it as open source.
- [Durran Jordan](https://github.com/durran) allowed the usage of the gem name at rubygems.org.
- [David Marchante](https://github.com/iovis) brainstormed the `initialize`/`call` approach, did all code reviews and provided lots of insightful feedback and suggestions. He also wrote the inline documentation.
- [Julio Antequera](https://github.com/jantequera), [Jimmi Carney](https://github.com/ayoformayo) and [Anthony Rocco](https://github.com/amrocco) had the patience to use it and report many bugs. Also most of the features in this gem came up when reviewing their usage of it. Anthony also made the effort of extracting the code from RubiconMD's codebase.
- [Rodrigo Álvarez](https://github.com/Papipo) had the idea for the DSL and actually wrote the library.
