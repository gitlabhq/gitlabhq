# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BillingEvents::InstanceIdentity, feature_category: :application_instrumentation do
  describe '#to_h' do
    subject(:identity) { described_class.to_h }

    it 'reports the six fields a billing event and an export both need' do
      expect(identity.keys).to match_array(
        %i[instance_id unique_instance_id host_name instance_version realm deployment_type]
      )
    end

    it 'resolves each field from live instance state' do
      expect(identity).to include(
        instance_id: Gitlab::GlobalAnonymousId.instance_id,
        unique_instance_id: Gitlab::GlobalAnonymousId.instance_uuid,
        host_name: Gitlab.config.gitlab.host,
        instance_version: Gitlab.version_info.to_s
      )
    end

    it 'reports no nil values, so an export cannot ship a blank identity' do
      expect(identity.values).to all(be_present)
    end
  end

  describe 'CE defaults' do
    def ce_value(name)
      method = described_class.instance_method(name)
      method = method.super_method until method.owner == described_class
      method.bind_call(described_class.new)
    end

    it 'describes an unconnected self-managed instance', :aggregate_failures do
      expect(ce_value(:realm)).to eq('SM')
      expect(ce_value(:deployment_type)).to eq('self-managed')
    end
  end

  describe 'REALM_MAP' do
    it 'maps every CloudConnector realm the billing schema accepts' do
      expect(described_class::REALM_MAP).to eq(
        'saas' => 'SaaS',
        'self-managed' => 'SM',
        'dedicated' => 'Dedicated'
      )
    end
  end
end
