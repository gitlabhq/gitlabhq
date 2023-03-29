# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'

require_relative '../../../../rubocop/cop/rspec/feature_category_on_shared_examples'

RSpec.describe RuboCop::Cop::RSpec::FeatureCategoryOnSharedExamples, feature_category: :tooling do
  it 'flags feature category in shared example' do
    expect_offense(<<~RUBY)
        RSpec.shared_examples 'foo', feature_category: :shared do
                                     ^^^^^^^^^^^^^^^^^^^^^^^^^ Shared examples should not have feature category set
        end

        shared_examples 'foo', feature_category: :shared do
                               ^^^^^^^^^^^^^^^^^^^^^^^^^ Shared examples should not have feature category set
        end
    RUBY
  end

  it 'does not flag if feature category is missing' do
    expect_no_offenses(<<~RUBY)
        RSpec.shared_examples 'foo' do
        end

        shared_examples 'foo', some: :tag do
        end
    RUBY
  end
end
