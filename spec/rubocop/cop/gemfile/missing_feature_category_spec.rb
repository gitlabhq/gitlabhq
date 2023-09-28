# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/gemfile/missing_feature_category'

RSpec.describe RuboCop::Cop::Gemfile::MissingFeatureCategory, feature_category: :tooling do
  let(:valid_category) { RuboCop::FeatureCategories.available.first }
  let(:invalid_category) { :invalid_category }

  it 'flags missing feature category in gem method without keyword argument' do
    expect_offense(<<~RUBY)
      gem 'foo', '~> 1.0'
      ^^^^^^^^^^^^^^^^^^^ Please use a valid feature category. See https://docs.gitlab.com/ee/development/feature_categorization/#gemfile
    RUBY
  end

  it 'flags missing feature category in gem method with keyword argument' do
    expect_offense(<<~RUBY)
      gem 'foo', '~> 1.0', require: false
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Please use a valid feature category. See https://docs.gitlab.com/ee/development/feature_categorization/#gemfile
    RUBY
  end

  it 'flags invalid feature category in gem method as the only keyword argument' do
    expect_offense(<<~RUBY, invalid: invalid_category)
      gem 'foo', '~> 1.0', feature_category: :%{invalid}
                                             ^^{invalid} Please use a valid feature category. See https://docs.gitlab.com/ee/development/feature_categorization/#gemfile
    RUBY
  end

  it 'flags invalid feature category in gem method as the last keyword argument' do
    expect_offense(<<~RUBY, invalid: invalid_category)
      gem 'foo', '~> 1.0', require: false, feature_category: :%{invalid}
                                                             ^^{invalid} Please use a valid feature category. See https://docs.gitlab.com/ee/development/feature_categorization/#gemfile
    RUBY
  end

  it 'flags invalid feature category in gem method as the first keyword argument' do
    expect_offense(<<~RUBY, invalid: invalid_category)
      gem 'foo', '~> 1.0', feature_category: :%{invalid}, require: false
                                             ^^{invalid} Please use a valid feature category. See https://docs.gitlab.com/ee/development/feature_categorization/#gemfile
    RUBY
  end

  it 'does not flag in gem method if feature category is valid as the only keyword argument' do
    expect_no_offenses(<<~RUBY)
      gem 'foo', '~> 1.0', feature_category: :#{valid_category}
    RUBY
  end

  it 'does not flag in gem method if feature category is valid as the last keyword argument' do
    expect_no_offenses(<<~RUBY)
      gem 'foo', '~> 1.0', require: false, feature_category: :#{valid_category}
    RUBY
  end

  describe '#external_dependency_checksum' do
    it 'returns a SHA256 digest used by RuboCop to invalid cache' do
      expect(cop.external_dependency_checksum).to match(/^\h{64}$/)
    end
  end
end
