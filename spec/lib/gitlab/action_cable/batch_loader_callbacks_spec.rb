# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ActionCable::BatchLoaderCallbacks, feature_category: :api do
  describe '.wrapper' do
    let(:batched_value) do
      -> { BatchLoader.for(:key).batch { |keys, loader| keys.each { |k| loader.call(k, SecureRandom.uuid) } }.to_s }
    end

    it 'does not reuse values batched by an earlier task' do
      first = described_class.wrapper.call(nil, batched_value)

      expect(described_class.wrapper.call(nil, batched_value)).not_to eq(first)
    end

    it 'clears the executor when the task raises' do
      expect do
        described_class.wrapper.call(nil, -> { batched_value.call && raise('test_exception') })
      end.to raise_error('test_exception')

      expect(BatchLoader::Executor.current).to be_nil
    end

    context 'when clear_action_cable_loader is disabled' do
      before do
        stub_feature_flags(clear_action_cable_loader: false)
      end

      it 'reuses values batched by an earlier task' do
        first = described_class.wrapper.call(nil, batched_value)

        expect(described_class.wrapper.call(nil, batched_value)).to eq(first)
      end
    end
  end
end
