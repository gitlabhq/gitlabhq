# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Harbor do
  let(:url) { 'https://demo.goharbor.io' }
  let(:project_name) { 'testproject' }
  let(:username) { 'harborusername' }
  let(:password) { 'harborpassword' }
  let(:harbor_integration) { build(:harbor_integration) }

  it_behaves_like Integrations::ResetSecretFields do
    let(:integration) { described_class.new }
  end

  describe "masked password" do
    subject { build(:harbor_integration) }

    it { is_expected.not_to allow_value('hello').for(:password) }
    it { is_expected.not_to allow_value('hello world').for(:password) }
    it { is_expected.not_to allow_value('hello$VARIABLEworld').for(:password) }
    it { is_expected.not_to allow_value('hello\rworld').for(:password) }
    it { is_expected.to allow_value('helloworld').for(:password) }
  end

  describe 'url' do
    subject { build(:harbor_integration) }

    it { is_expected.not_to allow_value('https://192.168.1.1').for(:url) }
    it { is_expected.not_to allow_value('https://127.0.0.1').for(:url) }
    it { is_expected.to allow_value('https://demo.goharbor.io').for(:url) }
  end

  describe 'hostname' do
    it 'returns the host of the integration url' do
      expect(harbor_integration.hostname).to eq('demo.goharbor.io')
    end
  end

  describe '#fields' do
    it 'returns custom fields' do
      expect(harbor_integration.fields.pluck(:name)).to eq(%w[url project_name username password])
    end
  end

  describe '#test' do
    let(:test_response) { "pong" }

    before do
      allow_next_instance_of(Gitlab::Harbor::Client) do |client|
        allow(client).to receive(:check_project_availability).and_return(test_response)
      end
    end

    it 'gets response from Gitlab::Harbor::Client#ping' do
      expect(harbor_integration.test).to eq(test_response)
    end
  end

  describe '#help' do
    it 'renders prompt information' do
      expect(harbor_integration.help).not_to be_empty
    end
  end

  describe '.to_param' do
    it 'returns the name of the integration' do
      expect(described_class.to_param).to eq('harbor')
    end
  end

  context 'ci variables' do
    let(:harbor_integration) { build_stubbed(:harbor_integration) }

    it 'returns vars when harbor_integration is activated' do
      ci_vars = [
        { key: 'HARBOR_URL', value: url },
        { key: 'HARBOR_HOST', value: 'demo.goharbor.io' },
        { key: 'HARBOR_OCI', value: 'oci://demo.goharbor.io' },
        { key: 'HARBOR_PROJECT', value: project_name },
        { key: 'HARBOR_USERNAME', value: username },
        { key: 'HARBOR_PASSWORD', value: password, public: false, masked: true }
      ]

      expect(harbor_integration.ci_variables).to match_array(ci_vars)
    end

    context 'when harbor_integration is inactive' do
      let(:harbor_integration) { build_stubbed(:harbor_integration, active: false) }

      it 'returns []' do
        expect(harbor_integration.ci_variables).to be_empty
      end
    end

    context 'with robot username' do
      it 'returns username variable with $$' do
        harbor_integration.username = 'robot$project+user'

        expect(harbor_integration.ci_variables).to include(
          { key: 'HARBOR_USERNAME', value: 'robot$$project+user' }
        )
      end
    end
  end
end
