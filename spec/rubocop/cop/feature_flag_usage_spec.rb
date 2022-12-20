# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../rubocop/cop/feature_flag_usage'

RSpec.describe RuboCop::Cop::FeatureFlagUsage, feature_category: :scalability do
  let(:msg) { described_class::MSG }

  context 'when calling Feature.enabled?' do
    it 'registers offence' do
      expect_offense(<<~PATTERN)
        Feature.enabled?(:fflag)
        ^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end

    it 'registers offence when called with type parameter' do
      expect_offense(<<~PATTERN)
        Feature.enabled?(:fflag, type: :ops)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end

    it 'registers offence when called under global namespace' do
      expect_offense(<<~PATTERN)
        ::Feature.enabled?(:fflag, type: :ops)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end
  end

  context 'when calling Feature.disabled?' do
    it 'registers offence' do
      expect_offense(<<~PATTERN)
        Feature.disabled?(:fflag)
        ^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end

    it 'registers offence when called with type parameter' do
      expect_offense(<<~PATTERN)
        Feature.disabled?(:fflag, type: :ops)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end

    it 'registers offence when called under global namespace' do
      expect_offense(<<~PATTERN)
        ::Feature.disabled?(:fflag, type: :ops)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      PATTERN
    end
  end
end
