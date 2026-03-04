# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ClickHouse::TableSettingsNormalizer, feature_category: :database do
  describe '#run' do
    let(:version) { '25.1' }

    let(:processed_statement) { described_class.run(statement, version) }

    context 'when statement includes MODIFY SETTING but not rebuild mode' do
      let(:statement) { 'ALTER TABLE test MODIFY SETTING deduplicate_merge_projection_mode = 0' }

      it 'returns the original statement' do
        expect(processed_statement).to eq(statement)
      end
    end

    context 'when ClickHouse version is >= 24.8' do
      let(:version) { '24.8.1.1' }
      let(:statement) { "CREATE TABLE test (...) SETTINGS deduplicate_merge_projection_mode = 'rebuild'" }

      it 'returns the original statement' do
        expect(processed_statement).to eq(statement)
      end
    end

    context 'when ClickHouse version is < 24.8' do
      let(:version) { '23.8' }

      context 'when there is another setting after deduplicate_merge_projection_mode' do
        let(:statement) do
          "CREATE TABLE test (...) SETTINGS deduplicate_merge_projection_mode = 'rebuild', index_granularity = 8192"
        end

        it 'removes the setting with comma after' do
          expect(processed_statement).to eq('CREATE TABLE test (...) SETTINGS index_granularity = 8192')
        end
      end

      context 'when it is the last setting' do
        let(:statement) do
          "CREATE TABLE test (...) SETTINGS index_granularity = 8192, deduplicate_merge_projection_mode = 'rebuild'"
        end

        it 'removes the setting with comma before' do
          expect(processed_statement).to eq('CREATE TABLE test (...) SETTINGS index_granularity = 8192')
        end
      end

      context 'when it is the only setting' do
        let(:statement) { "CREATE TABLE test (...) SETTING deduplicate_merge_projection_mode = 'rebuild'" }

        it 'removes the setting when it is the only setting' do
          expect(processed_statement).to eq('CREATE TABLE test (...) ')
        end
      end
    end
  end
end
