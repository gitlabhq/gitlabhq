# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::FilterEvaluator, feature_category: :duo_agent_platform do
  describe '.evaluate' do
    subject(:evaluate) { described_class.evaluate(filter, data) }

    before do
      # The real logger needs the Rails request store, which fast_spec_helper does not load.
      allow(Gitlab::AppLogger).to receive(:debug)
    end

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

    context 'when an intermediate path segment is missing from the data' do
      let(:filter) do
        {
          'rules' => [
            { 'field' => 'status.name', 'operator' => 'eq', 'value' => 'In progress' }
          ]
        }
      end

      it 'does not match and does not log an evaluation error' do
        expect(Gitlab::AppLogger).not_to receive(:error)

        expect(evaluate).to be(false)
      end

      it 'logs the untraversable segment at debug level' do
        expect(Gitlab::AppLogger).to receive(:debug).with(
          hash_including(class: 'Gitlab::FilterEvaluator', field: 'status.name', stopped_at: 'name')
        )

        evaluate
      end

      context 'with match any and another matching rule' do
        let(:filter) do
          {
            'match' => 'any',
            'rules' => [
              { 'field' => 'status.name', 'operator' => 'eq', 'value' => 'In progress' },
              { 'field' => 'object_attributes.status', 'operator' => 'eq', 'value' => 'failed' }
            ]
          }
        end

        it 'still matches on the other rule' do
          expect(Gitlab::AppLogger).not_to receive(:error)

          expect(evaluate).to be(true)
        end
      end
    end

    context 'when the data is nil' do
      let(:data) { nil }
      let(:filter) do
        { 'rules' => [{ 'field' => 'object_attributes.status', 'operator' => 'eq', 'value' => 'failed' }] }
      end

      it 'does not match and does not log an evaluation error' do
        expect(Gitlab::AppLogger).not_to receive(:error)

        expect(evaluate).to be(false)
      end
    end

    context 'when the path traverses a non-hash value' do
      let(:filter) do
        { 'rules' => [{ 'field' => 'object_attributes.status.name', 'operator' => 'eq', 'value' => 'failed' }] }
      end

      it 'does not match and does not log an evaluation error' do
        expect(Gitlab::AppLogger).not_to receive(:error)

        expect(evaluate).to be(false)
      end
    end

    context 'when the data is a hash-like delegator' do
      let(:data) { SimpleDelegator.new(super()) }
      let(:filter) do
        { 'rules' => [{ 'field' => 'object_attributes.status', 'operator' => 'in', 'value' => ['failed'] }] }
      end

      it { is_expected.to be(true) }
    end

    context 'when a string-keyed value is false' do
      let(:data) { { 'object_attributes' => { 'default_branch' => false } } }
      let(:filter) do
        { 'rules' => [{ 'field' => 'object_attributes.default_branch', 'operator' => 'eq', 'value' => false }] }
      end

      it { is_expected.to be(true) }
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
        innermost = { 'field' => 'object_attributes.status', 'operator' => 'eq', 'value' => 'success' }

        (described_class::MAX_DEPTH + 1).times.reduce(innermost) do |inner, _|
          { 'type' => 'group', 'rules' => [inner] }
        end
      end

      it_behaves_like 'logs and returns false'
    end
  end
end
