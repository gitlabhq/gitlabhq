# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceHook do
  describe 'associations' do
    it { is_expected.to belong_to :integration }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:integration) }
  end

  describe 'execute' do
    let(:hook) { build(:service_hook) }
    let(:data) { { key: 'value' } }

    it '#execute' do
      expect(WebHookService).to receive(:new).with(hook, data, 'service_hook').and_call_original
      expect_any_instance_of(WebHookService).to receive(:execute)

      hook.execute(data)
    end
  end

  describe '#rate_limit' do
    let(:hook) { build(:service_hook) }

    it 'returns nil' do
      expect(hook.rate_limit).to be_nil
    end
  end

  describe '#application_context' do
    let(:hook) { build(:service_hook) }

    it 'includes the type' do
      expect(hook.application_context).to eq(
        related_class: 'ServiceHook'
      )
    end
  end
end
