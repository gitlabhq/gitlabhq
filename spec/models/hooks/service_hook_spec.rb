# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceHook, feature_category: :webhooks do
  it_behaves_like 'a hook that does not get automatically disabled on failure' do
    let(:integration) { build(:integration) }
    let(:hook) { build(:service_hook) }
    let(:hook_factory) { :service_hook }
    let(:default_factory_arguments) { { integration: integration } }

    def find_hooks
      described_class.all
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:integration) }
    it { is_expected.to have_many(:web_hook_logs) }
  end

  describe '#destroy' do
    it 'does not cascade to web_hook_logs' do
      web_hook = create(:service_hook)
      create_list(:web_hook_log, 3, web_hook: web_hook)

      expect { web_hook.destroy! }.not_to change { web_hook.web_hook_logs.count }
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:integration) }
  end

  describe 'execute' do
    let(:hook) { build(:service_hook) }
    let(:data) { { key: 'value' } }

    it '#execute' do
      expect(WebHookService).to receive(:new).with(hook, data, 'service_hook', idempotency_key: anything,
        force: false).and_call_original
      expect_any_instance_of(WebHookService).to receive(:execute)

      hook.execute(data)
    end
  end

  describe '#parent' do
    let(:hook) { build(:service_hook, integration: integration) }

    context 'with a project-level integration' do
      let(:project) { build(:project) }
      let(:integration) { build(:integration, project: project) }

      it 'returns the associated project' do
        expect(hook.parent).to eq(project)
      end
    end

    context 'with a group-level integration' do
      let(:group) { build(:group) }
      let(:integration) { build(:integration, :group, group: group) }

      it 'returns the associated group' do
        expect(hook.parent).to eq(group)
      end
    end

    context 'with an instance-level integration' do
      let(:integration) { build(:integration, :instance) }

      it 'returns nil' do
        expect(hook.parent).to be_nil
      end
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
