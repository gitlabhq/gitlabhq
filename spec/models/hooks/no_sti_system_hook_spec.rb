# frozen_string_literal: true

require "spec_helper"

RSpec.describe NoStiSystemHook, feature_category: :webhooks do
  it_behaves_like 'a webhook', factory: :no_sti_system_hook, auto_disabling: false

  it_behaves_like 'a hook that does not get automatically disabled on failure' do
    let(:hook) { build(:no_sti_system_hook) }
    let(:hook_factory) { :no_sti_system_hook }
    let(:default_factory_arguments) { {} }

    def find_hooks
      described_class.all
    end
  end

  describe 'default attributes' do
    let(:no_sti_system_hook) { described_class.new }

    it 'sets defined default parameters' do
      attrs = {
        push_events: false,
        repository_update_events: true,
        merge_requests_events: false
      }
      expect(no_sti_system_hook).to have_attributes(attrs)
    end
  end

  describe 'associations' do
    it { is_expected.not_to respond_to(:web_hook_logs) }
  end

  describe 'validations' do
    describe 'url' do
      let(:url) { 'http://localhost:9000' }

      it { is_expected.not_to allow_value(url).for(:url) }

      it 'is valid if application settings allow local requests from system hooks' do
        settings = ApplicationSetting.new(allow_local_requests_from_system_hooks: true)
        allow(ApplicationSetting).to receive(:current).and_return(settings)

        is_expected.to allow_value(url).for(:url)
      end
    end
  end

  describe '.repository_update_hooks' do
    it 'returns hooks for repository update events only' do
      hook = create(:no_sti_system_hook, repository_update_events: true)
      create(:no_sti_system_hook, repository_update_events: false)
      expect(described_class.repository_update_hooks).to eq([hook])
    end
  end

  describe 'execute WebHookService' do
    let(:hook) { build(:no_sti_system_hook) }
    let(:data) { { key: 'value' } }
    let(:hook_name) { 'no_sti_system_hook' }
    let(:web_hook_service) { instance_double(WebHookService, execute: true) }

    it '#execute' do
      expect(WebHookService).to receive(:new).with(hook, data, hook_name, idempotency_key: anything, force: false)
        .and_return(web_hook_service)

      expect(web_hook_service).to receive(:execute)

      hook.execute(data, hook_name)
    end

    it '#async_execute' do
      expect(WebHookService).to receive(:new).with(hook, data, hook_name, idempotency_key: anything)
        .and_return(web_hook_service)

      expect(web_hook_service).to receive(:async_execute)

      hook.async_execute(data, hook_name)
    end
  end

  describe '#application_context' do
    let(:hook) { build(:no_sti_system_hook) }

    it 'includes the type' do
      expect(hook.application_context).to eq(
        related_class: 'NoStiSystemHook'
      )
    end
  end
end
