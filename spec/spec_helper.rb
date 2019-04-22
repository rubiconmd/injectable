require "bundler/setup"
require "injectable"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.mock_with :mocha

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
