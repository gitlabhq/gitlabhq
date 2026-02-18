# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::FilterEvaluator, feature_category: :duo_agent_platform do
  describe '.evaluate' do
    subject(:evaluate) { described_class.evaluate(filter, data) }

    let(:data) do
      {
        object_attributes: {
          status: 'failed',
          ref: 'main',
          duration: 7200
        },
        user: {
          id: 42,
          username: 'bot-user'
        }
      }
    end

    context 'when filter is blank' do
      let(:filter) { nil }

      it { is_expected.to be(true) }
    end

    context 'when filter is empty' do
      let(:filter) { {} }

      it { is_expected.to be(true) }
    end

    context 'with a simple rule' do
      let(:filter) do
        {
          'rules' => [
            { 'field' => 'object_attributes.status', 'operator' => 'eq', 'value' => 'failed' }
          ]
        }
      end

      it { is_expected.to be(true) }

      context 'with no match' do
        let(:filter) do
          {
            'rules' => [
              { 'field' => 'object_attributes.status', 'operator' => 'eq', 'value' => 'success' }
            ]
          }
        end

        it { is_expected.to be(false) }
      end
    end

    context 'with match any' do
      let(:filter) do
        {
          'rules' => [
            { 'field' => 'object_attributes.status', 'operator' => 'eq', 'value' => 'success' },
            { 'field' => 'object_attributes.ref', 'operator' => 'eq', 'value' => 'main' }
          ],
          'match' => 'any'
        }
      end

      it { is_expected.to be(true) }

      context 'with no match' do
        let(:filter) do
          {
            'rules' => [
              { 'field' => 'object_attributes.status', 'operator' => 'eq', 'value' => 'success' },
              { 'field' => 'object_attributes.ref', 'operator' => 'eq', 'value' => 'master' }
            ],
            'match' => 'any'
          }
        end

        it { is_expected.to be(false) }
      end
    end

    context 'with grouped rules' do
      let(:filter) do
        {
          'rules' => [
            {
              'type' => 'group',
              'match' => 'any',
              'rules' => [
                { 'field' => 'object_attributes.status', 'operator' => 'eq', 'value' => 'success' },
                { 'field' => 'object_attributes.status', 'operator' => 'eq', 'value' => 'failed' }
              ]
            },
            { 'field' => 'object_attributes.duration', 'operator' => 'gt', 'value' => 3600 }
          ],
          'match' => 'all'
        }
      end

      it { is_expected.to be(true) }
    end

    context 'with all supported operators' do
      let(:filter) do
        {
          'rules' => [
            { 'field' => 'object_attributes.status', 'operator' => 'eq', 'value' => 'failed' },
            { 'field' => 'object_attributes.status', 'operator' => 'ne', 'value' => 'success' },
            { 'field' => 'object_attributes.duration', 'operator' => 'gt', 'value' => 100 },
            { 'field' => 'object_attributes.duration', 'operator' => 'lt', 'value' => 10000 },
            { 'field' => 'object_attributes.ref', 'operator' => 'contains', 'value' => 'mai' },
            { 'field' => 'user.id', 'operator' => 'in', 'value' => [1, 42] },
            { 'field' => 'object_attributes.ref', 'operator' => 'not_contains', 'value' => 'release' },
            { 'field' => 'user.id', 'operator' => 'not_in', 'value' => [1, 7] }
          ],
          'match' => 'all'
        }
      end

      it { is_expected.to be(true) }
    end

    it 'resolves values from string and symbol keys' do
      filter = {
        'rules' => [
          { 'field' => 'user.username', 'operator' => 'eq', 'value' => 'bot-user' }
        ]
      }

      expect(described_class.evaluate(filter, data.deep_stringify_keys)).to be(true)
      expect(described_class.evaluate(filter, data.deep_symbolize_keys)).to be(true)
    end

    shared_examples 'logs and returns false' do
      it 'logs and returns false' do
        expect(Gitlab::AppLogger).to receive(:error).with(/Filter evaluation error/)

        expect(evaluate).to be(false)
      end
    end

    context 'when operator is unknown' do
      let(:filter) do
        {
          'rules' => [
            { 'field' => 'object_attributes.status', 'operator' => 'nope', 'value' => 'failed' }
          ]
        }
      end

      it_behaves_like 'logs and returns false'
    end

    context 'when max depth is exceeded' do
      let(:filter) do
        deep_filter = { 'type' => 'group', 'rules' => [] }
        current = deep_filter
        (described_class::MAX_DEPTH + 1).times do
          next_group = { 'type' => 'group', 'rules' => [] }
          current['rules'] = [next_group]
          current = next_group
        end
      end

      it_behaves_like 'logs and returns false'
    end
  end
end
