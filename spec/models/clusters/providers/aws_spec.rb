# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Providers::Aws do
  it { is_expected.to belong_to(:cluster) }

  it { is_expected.to validate_length_of(:key_name).is_at_least(1).is_at_most(255) }
  it { is_expected.to validate_length_of(:region).is_at_least(1).is_at_most(255) }
  it { is_expected.to validate_length_of(:instance_type).is_at_least(1).is_at_most(255) }
  it { is_expected.to validate_length_of(:security_group_id).is_at_least(1).is_at_most(255) }
  it { is_expected.to validate_presence_of(:subnet_ids) }

  include_examples 'provider status', :cluster_provider_aws

  describe 'default values' do
    let(:provider) { build(:cluster_provider_aws) }

    it "sets default values" do
      expect(provider.region).to eq('us-east-1')
      expect(provider.num_nodes).to eq(3)
      expect(provider.instance_type).to eq('m5.large')
    end
  end

  describe 'custom validations' do
    subject { provider.valid? }

    context ':num_nodes' do
      let(:provider) { build(:cluster_provider_aws, num_nodes: num_nodes) }

      context 'contains non-digit characters' do
        let(:num_nodes) { 'A3' }

        it { is_expected.to be_falsey }
      end

      context 'is blank' do
        let(:num_nodes) { nil }

        it { is_expected.to be_falsey }
      end

      context 'is less than 1' do
        let(:num_nodes) { 0 }

        it { is_expected.to be_falsey }
      end

      context 'is a positive integer' do
        let(:num_nodes) { 3 }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#nullify_credentials' do
    let(:provider) { create(:cluster_provider_aws, :scheduled) }

    subject { provider.nullify_credentials }

    before do
      expect(provider.access_key_id).to be_present
      expect(provider.secret_access_key).to be_present
      expect(provider.session_token).to be_present
    end

    it 'removes access_key_id, secret_access_key and session_token' do
      subject

      expect(provider.access_key_id).to be_nil
      expect(provider.secret_access_key).to be_nil
      expect(provider.session_token).to be_nil
    end
  end

  describe '#created_by_user' do
    let(:provider) { create(:cluster_provider_aws) }

    subject { provider.created_by_user }

    it { is_expected.to eq provider.cluster.user }
  end

  describe '#has_rbac_enabled?' do
    let(:provider) { create(:cluster_provider_aws) }

    subject { provider.has_rbac_enabled? }

    it { is_expected.to be_truthy }
  end

  describe '#knative_pre_installed?' do
    let(:provider) { create(:cluster_provider_aws) }

    subject { provider.knative_pre_installed? }

    it { is_expected.to be_falsey }
  end
end
