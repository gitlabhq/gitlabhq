# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../rubocop/cop/feature_flag_usage'

RSpec.describe RuboCop::Cop::FeatureFlagUsage, feature_category: :scalability do
  let(:msg) { described_class::MSG }

  context 'when calling Feature.enabled?' do
    it 'registers offence' do
      expect_offense(<<~RUBY)
        Feature.enabled?(:fflag)
        ^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offence when called with type parameter' do
      expect_offense(<<~RUBY)
        Feature.enabled?(:fflag, type: :ops)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offence when called under global namespace' do
      expect_offense(<<~RUBY)
        ::Feature.enabled?(:fflag, type: :ops)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end
  end

  context 'when calling Feature.disabled?' do
    it 'registers offence' do
      expect_offense(<<~RUBY)
        Feature.disabled?(:fflag)
        ^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offence when called with type parameter' do
      expect_offense(<<~RUBY)
        Feature.disabled?(:fflag, type: :ops)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offence when called under global namespace' do
      expect_offense(<<~RUBY)
        ::Feature.disabled?(:fflag, type: :ops)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end
  end
end
