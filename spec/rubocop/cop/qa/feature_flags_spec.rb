# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/qa/feature_flags'

RSpec.describe RuboCop::Cop::QA::FeatureFlags, feature_category: :quality_management do
  shared_examples 'registers no offense' do
    it 'does not register an offense' do
      expect_no_offenses(source)
    end
  end

  it 'registers an offense when using Runtime::Feature without :feature_flag' do
    expect_offense(<<~RUBY)
      describe 'some test' do
        it 'does something' do
          Runtime::Feature.disable(:flag)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Apply the `feature_flag: { name: :flag }` metadata to the test to use `Runtime::Feature` in end-to-end tests.
        end
      end
    RUBY
  end

  it 'registers an offense when using QA::Runtime::Feature without :feature_flag' do
    expect_offense(<<~RUBY)
      describe 'some test' do
        it 'does something' do
          QA::Runtime::Feature.disable(:flag)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Apply the `feature_flag: { name: :flag }` metadata to the test to use `QA::Runtime::Feature` in end-to-end tests.
        end
      end
    RUBY
  end

  context 'when the test has :feature_flag metadata' do
    let(:source) do
      <<~RUBY
        describe 'some test', :feature_flag do
          it 'does something' do
            Runtime::Feature.enable(:flag)
          end
        end
      RUBY
    end

    it 'requests that the metadata be converted to a block' do
      expect_offense(<<~RUBY)
        describe 'some test', :feature_flag do
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Feature flags must specify a name. Use a block with `feature_flag: { name: :flag }` instead.
        end
      RUBY
    end
  end

  context 'when using a fully-qualified constant' do
    let(:source) do
      <<~RUBY
        describe 'some test', feature_flag: { name: :flag } do
          it 'does something' do
            QA::Runtime::Feature.enable(:flag)
          end
        end
      RUBY
    end

    it_behaves_like 'registers no offense'
  end

  context 'when using a :feature_flag block' do
    let(:source) do
      <<~RUBY
        describe 'some test', feature_flag: { name: :flag } do
          it 'does something' do
            Runtime::Feature.enable(:flag)
          end
        end
      RUBY
    end

    it_behaves_like 'registers no offense'
  end

  context 'when using a :feature_flag block with a scope' do
    let(:source) do
      <<~RUBY
        describe 'some test', feature_flag: { name: :flag, scope: :global } do
          it 'does something' do
            Runtime::Feature.disable(:flag)
          end
        end
      RUBY
    end

    it_behaves_like 'registers no offense'
  end
end
