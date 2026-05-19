# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/rspec/feature_spec_max_examples'

RSpec.describe RuboCop::Cop::RSpec::FeatureSpecMaxExamples, feature_category: :tooling do
  let(:max) { 3 }

  let(:cop_config) { { 'Max' => max } }

  context 'when the number of examples is within the limit' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe 'Feature' do
          it 'test 1' do
          end

          it 'test 2' do
          end

          it 'test 3' do
          end
        end
      RUBY
    end
  end

  context 'when the number of examples exceeds the limit' do
    it 'registers an offense on the describe block' do
      expect_offense(<<~RUBY)
        RSpec.describe 'Feature' do
        ^^^^^^^^^^^^^^^^^^^^^^^^ Feature spec file has 4 examples, which exceeds the maximum of 3. Consider splitting into smaller, focused files grouped by user flow or feature area.
          it 'test 1' do
          end

          it 'test 2' do
          end

          it 'test 3' do
          end

          it 'test 4' do
          end
        end
      RUBY
    end
  end

  context 'when the number of examples greatly exceeds the limit' do
    it 'still registers only a single offense on the describe block' do
      expect_offense(<<~RUBY)
        RSpec.describe 'Feature' do
        ^^^^^^^^^^^^^^^^^^^^^^^^ Feature spec file has 5 examples, which exceeds the maximum of 3. Consider splitting into smaller, focused files grouped by user flow or feature area.
          it 'test 1' do
          end

          it 'test 2' do
          end

          it 'test 3' do
          end

          it 'test 4' do
          end

          it 'test 5' do
          end
        end
      RUBY
    end
  end

  context 'when examples use specify instead of it' do
    it 'counts specify blocks toward the limit' do
      expect_offense(<<~RUBY)
        RSpec.describe 'Feature' do
        ^^^^^^^^^^^^^^^^^^^^^^^^ Feature spec file has 4 examples, which exceeds the maximum of 3. Consider splitting into smaller, focused files grouped by user flow or feature area.
          specify 'test 1' do
          end

          specify 'test 2' do
          end

          specify 'test 3' do
          end

          specify 'test 4' do
          end
        end
      RUBY
    end
  end

  context 'when there are no examples' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe 'Feature' do
          context 'some context' do
          end
        end
      RUBY
    end
  end
end
