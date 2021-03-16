# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../rubocop/cop/usage_data/large_table'

RSpec.describe RuboCop::Cop::UsageData::LargeTable do
  let(:large_tables) { %i[Rails Time] }
  let(:count_methods) { %i[count distinct_count] }
  let(:allowed_methods) { %i[minimum maximum] }
  let(:msg) { 'Use one of the count, distinct_count methods for counting on' }

  let(:config) do
    RuboCop::Config.new('UsageData/LargeTable' => {
                          'NonRelatedClasses' => large_tables,
                          'CountMethods' => count_methods,
                          'AllowedMethods' => allowed_methods
                        })
  end

  subject(:cop) { described_class.new(config) }

  context 'when in usage_data files' do
    before do
      allow(cop).to receive(:usage_data_files?).and_return(true)
    end

    context 'with large tables' do
      context 'when calling Issue.count' do
        it 'registers an offense' do
          expect_offense(<<~CODE)
            Issue.count
            ^^^^^^^^^^^ #{msg} Issue
          CODE
        end
      end

      context 'when calling Issue.active.count' do
        it 'registers an offense' do
          expect_offense(<<~CODE)
            Issue.active.count
            ^^^^^^^^^^^^ #{msg} Issue
          CODE
        end
      end

      context 'when calling count(Issue)' do
        it 'does not register an offense' do
          expect_no_offenses('count(Issue)')
        end
      end

      context 'when calling count(Ci::Build.active)' do
        it 'does not register an offense' do
          expect_no_offenses('count(Ci::Build.active)')
        end
      end

      context 'when calling Ci::Build.active.count' do
        it 'registers an offense' do
          expect_offense(<<~CODE)
            Ci::Build.active.count
            ^^^^^^^^^^^^^^^^ #{msg} Ci::Build
          CODE
        end
      end

      context 'when using allowed methods' do
        it 'does not register an offense' do
          expect_no_offenses('Issue.minimum')
        end
      end
    end

    context 'with non related class' do
      it 'does not register an offense' do
        expect_no_offenses('Rails.count')
      end
    end
  end
end
