require 'spec_helper'

describe CheckGcpProjectBillingService do
  let(:service) { described_class.new }

  describe '#execute' do
    before do
      expect_any_instance_of(GoogleApi::CloudPlatform::Client)
        .to receive(:projects_list).and_return([double(name: 'project_name')])

      expect_any_instance_of(GoogleApi::CloudPlatform::Client)
        .to receive_message_chain(:projects_get_billing_info, :billingEnabled)
        .and_return(project_billing_enabled)
    end

    subject { service.execute('bogustoken') }

    context 'google account has a billing enabled gcp project' do
      let(:project_billing_enabled) { true }

      it { is_expected.to eq(true) }
    end

    context 'google account does not have a billing enabled gcp project' do
      let(:project_billing_enabled) { false }

      it { is_expected.to eq(false) }
    end
  end
end
