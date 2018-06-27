require 'rubocop/rspec/support'

# https://github.com/backus/rubocop-rspec/blob/master/spec/support/expect_offense.rb
# rubocop-rspec gem extension of RuboCop's ExpectOffense module.
#
# This mixin is the same as rubocop's ExpectOffense except the default
# filename ends with `_spec.rb`
module ExpectOffense
  include RuboCop::RSpec::ExpectOffense

  DEFAULT_FILENAME = 'example_spec.rb'.freeze

  def expect_offense(source, filename = DEFAULT_FILENAME)
    super
  end

  def expect_no_offenses(source, filename = DEFAULT_FILENAME)
    super
  end
end
