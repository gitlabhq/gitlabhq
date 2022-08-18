# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Harbor do
  let(:url) { 'https://demo.goharbor.io' }
  let(:project_name) { 'testproject' }
  let(:username) { 'harborusername' }
  let(:password) { 'harborpassword' }
  let(:harbor_integration) { create(:harbor_integration) }

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

  describe '#fields' do
    it 'returns custom fields' do
      expect(harbor_integration.fields.pluck(:name)).to eq(%w[url project_name username password])
    end
  end

  describe '#test' do
    let(:test_response) { "pong" }

    before do
      allow_next_instance_of(Gitlab::Harbor::Client) do |client|
        allow(client).to receive(:ping).and_return(test_response)
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

    it 'returns [] when harbor_integration is inactive' do
      harbor_integration.update!(active: false)
      expect(harbor_integration.ci_variables).to match_array([])
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

  describe 'before_validation :reset_username_and_password' do
    context 'when username/password was previously set' do
      it 'resets username and password if url changed' do
        harbor_integration.url = 'https://anotherharbor.com'
        harbor_integration.valid?

        expect(harbor_integration.password).to be_nil
        expect(harbor_integration.username).to be_nil
      end

      it 'does not reset password if username changed' do
        harbor_integration.username = 'newusername'
        harbor_integration.valid?

        expect(harbor_integration.password).to eq('harborpassword')
      end

      it 'does not reset username if password changed' do
        harbor_integration.password = 'newpassword'
        harbor_integration.valid?

        expect(harbor_integration.username).to eq('harborusername')
      end

      it "does not reset password if new url is set together with password, even if it's the same password" do
        harbor_integration.url = 'https://anotherharbor.com'
        harbor_integration.password = 'harborpassword'
        harbor_integration.valid?

        expect(harbor_integration.password).to eq('harborpassword')
        expect(harbor_integration.username).to be_nil
        expect(harbor_integration.url).to eq('https://anotherharbor.com')
      end

      it "does not reset username if new url is set together with username, even if it's the same username" do
        harbor_integration.url = 'https://anotherharbor.com'
        harbor_integration.username = 'harborusername'
        harbor_integration.valid?

        expect(harbor_integration.password).to be_nil
        expect(harbor_integration.username).to eq('harborusername')
        expect(harbor_integration.url).to eq('https://anotherharbor.com')
      end
    end

    it 'saves password if new url is set together with password when no password was previously set' do
      harbor_integration.password = nil
      harbor_integration.username = nil

      harbor_integration.url = 'https://anotherharbor.com'
      harbor_integration.password = 'newpassword'
      harbor_integration.username = 'newusername'
      harbor_integration.save!

      expect(harbor_integration).to have_attributes(
        url: 'https://anotherharbor.com',
        password: 'newpassword',
        username: 'newusername'
      )
    end
  end
end
