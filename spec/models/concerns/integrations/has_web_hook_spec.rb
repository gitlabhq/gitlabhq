# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::HasWebHook, feature_category: :webhooks do
  let(:integration_class) do
    Class.new(Integration) do
      include Integrations::HasWebHook
    end
  end

  let(:integration) { integration_class.new }

  context 'when hook_url and url_variables are not implemented' do
    it { expect { integration.hook_url }.to raise_error(NotImplementedError) }
    it { expect { integration.url_variables }.to raise_error(NotImplementedError) }
  end

  context 'when integration does not respond to enable_ssl_verification' do
    it { expect(integration.hook_ssl_verification).to eq true }
  end

  context 'when integration responds to enable_ssl_verification' do
    let(:integration) { build(:drone_ci_integration, enable_ssl_verification: true) }

    it { expect(integration.hook_ssl_verification).to eq true }
  end

  context 'when assigning a webhook sharding key' do
    before do
      allow(integration).to receive(:update_web_hook!).and_call_original
    end

    context 'when the integration is project level' do
      let(:project) { create(:project) }
      let(:integration) { create(:packagist_integration, project: project) }

      it 'assigns the project id' do
        integration.update_web_hook!

        expect(ServiceHook.last.project_id).to eq(project.id)
        expect(ServiceHook.last.group_id).to be_nil
        expect(ServiceHook.last.organization_id).to be_nil
      end
    end

    context 'when the integration is group level' do
      let(:group) { create(:group) }
      let(:integration) { create(:buildkite_integration, :group, group: group) }

      it 'assigns the group id' do
        integration.update_web_hook!

        expect(ServiceHook.last.group_id).to eq(group.id)
        expect(ServiceHook.last.project_id).to be_nil
        expect(ServiceHook.last.organization_id).to be_nil
      end
    end

    context 'when the integration is instance level' do
      let(:organization) { create(:organization) }
      let(:integration) { create(:datadog_integration, :instance, organization: organization) }

      it 'assigns the organization id' do
        integration.update_web_hook!

        expect(ServiceHook.last.organization_id).to eq(organization.id)
        expect(ServiceHook.last.project_id).to be_nil
        expect(ServiceHook.last.group_id).to be_nil
      end
    end
  end
end
