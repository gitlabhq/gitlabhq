# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/rspec/missing_feature_category'

RSpec.describe RuboCop::Cop::RSpec::MissingFeatureCategory, feature_category: :tooling do
  it 'flags missing feature category in top level example group' do
    expect_offense(<<~RUBY)
      RSpec.describe 'foo' do
      ^^^^^^^^^^^^^^^^^^^^ Please add missing feature category. See https://docs.gitlab.com/ee/development/feature_categorization/#rspec-examples.
      end

      RSpec.describe 'foo', some: :tag do
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Please add missing feature category. See https://docs.gitlab.com/ee/development/feature_categorization/#rspec-examples.
      end
    RUBY
  end

  it 'does not flag if feature category is defined' do
    expect_no_offenses(<<~RUBY)
      RSpec.describe 'foo', feature_category: :foo do
      end

      RSpec.describe 'foo', some: :tag, feature_category: :foo do
      end

      RSpec.describe 'foo', feature_category: :foo, some: :tag do
      end
    RUBY
  end
end
