require 'spec_helper'

describe ServiceHook do
  describe 'associations' do
    it { is_expected.to belong_to :service }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:service) }
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
end
