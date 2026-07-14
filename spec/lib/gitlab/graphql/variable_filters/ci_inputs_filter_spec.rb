# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Graphql::VariableFilters::CiInputsFilter, feature_category: :continuous_integration do
  describe '.filter' do
    subject(:filtered) { described_class.filter(variables) }

    context 'when variables contain a top-level inputs array' do
      let(:variables) do
        { 'inputs' => [{ 'name' => 'deploy_strategy', 'value' => 'top-secret' }] }
      end

      it 'redacts value while preserving name' do
        expect(filtered['inputs']).to match_array([{ 'name' => 'deploy_strategy', 'value' => '[FILTERED]' }])
      end
    end

    context 'when inputs is nested inside a mutation input wrapper' do
      let(:variables) do
        {
          'input' => {
            'id' => 'gid://gitlab/Ci::PipelineSchedule/1',
            'inputs' => [{ 'name' => 'deploy_strategy', 'value' => 'top-secret' }]
          }
        }
      end

      it 'redacts value inside the nested inputs array' do
        nested = filtered['input']
        expect(nested['inputs']).to match_array([{ 'name' => 'deploy_strategy', 'value' => '[FILTERED]' }])
      end

      it 'preserves other fields in the wrapper' do
        expect(filtered['input']['id']).to eq('gid://gitlab/Ci::PipelineSchedule/1')
      end
    end

    context 'when inputs elements have no value key' do
      let(:variables) do
        { 'inputs' => [{ 'name' => 'deploy_strategy', 'destroy' => true }] }
      end

      it 'leaves elements without value unchanged' do
        expect(filtered['inputs']).to match_array([{ 'name' => 'deploy_strategy', 'destroy' => true }])
      end
    end

    context 'when variables do not contain inputs' do
      let(:variables) { { 'description' => 'nightly', 'cron' => '0 1 * * *' } }

      it 'returns variables unchanged' do
        expect(filtered).to eq(variables)
      end
    end

    context 'when variables is not a hash' do
      let(:variables) { nil }

      it 'returns the value unchanged' do
        expect(filtered).to be_nil
      end
    end
  end
end
