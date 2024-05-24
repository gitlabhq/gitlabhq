# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GrafanaIntegration do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:encrypted_token) }

    it 'disallows invalid urls for grafana_url' do
      unsafe_url = %{https://replaceme.com/'><script>alert(document.cookie)</script>}
      non_ascii_url = 'http://gitlab.com/api/0/projects/project1/something€'
      blank_url = ''
      excessively_long_url = 'https://grafan' + ('a' * 1024) + '.com'

      is_expected.not_to allow_values(
        unsafe_url,
        non_ascii_url,
        blank_url,
        excessively_long_url
      ).for(:grafana_url)
    end

    it 'allows valid urls for grafana_url' do
      external_url = 'http://grafana.com/'
      internal_url = 'http://192.168.1.1'

      is_expected.to allow_value(
        external_url,
        internal_url
      ).for(:grafana_url)
    end

    it 'disallows non-booleans in enabled column' do
      is_expected.not_to allow_value(
        nil
      ).for(:enabled)
    end

    it 'allows booleans in enabled column' do
      is_expected.to allow_value(
        true,
        false
      ).for(:enabled)
    end
  end

  describe '.client' do
    subject(:grafana_integration) { create(:grafana_integration) }

    context 'with grafana integration disabled' do
      it 'returns a grafana client' do
        expect(grafana_integration.client).to be_an_instance_of(::Grafana::Client)
      end
    end

    context 'with grafana integration enabled' do
      it 'returns nil' do
        grafana_integration.update!(enabled: false)

        expect(grafana_integration.client).to be(nil)
      end
    end
  end

  describe 'attribute encryption' do
    subject(:grafana_integration) { create(:grafana_integration, token: 'super-secret') }

    context 'token' do
      it 'encrypts original value into encrypted_token attribute' do
        expect(grafana_integration.encrypted_token).not_to be_nil
      end

      it 'locks access to raw value in private method', :aggregate_failures do
        expect { grafana_integration.token }.to raise_error(NoMethodError, /private method .token. called/)
        expect(grafana_integration.send(:token)).to eql('super-secret')
      end

      it 'prevents overriding token value with its encrypted or masked version', :aggregate_failures do
        expect { grafana_integration.update!(token: grafana_integration.encrypted_token) }.not_to change { grafana_integration.reload.send(:token) }
        expect { grafana_integration.update!(token: grafana_integration.masked_token) }.not_to change { grafana_integration.reload.send(:token) }
      end
    end
  end

  describe 'Callbacks' do
    describe 'before_validation :reset_token' do
      context 'when a token was previously set' do
        subject(:grafana_integration) { create(:grafana_integration) }

        it 'resets token if url changed' do
          grafana_integration.grafana_url = 'http://gitlab1.com'

          expect(grafana_integration).not_to be_valid
          expect(grafana_integration.send(:token)).to be_nil
        end

        it "does not reset token if new url is set together with the same token" do
          grafana_integration.grafana_url = 'http://gitlab_edited.com'
          current_token = grafana_integration.send(:token)
          grafana_integration.token = current_token

          expect(grafana_integration).to be_valid
          expect(grafana_integration.send(:token)).to eq(current_token)
          expect(grafana_integration.grafana_url).to eq('http://gitlab_edited.com')
        end

        it 'does not reset token if new url is set together with a new token' do
          grafana_integration.grafana_url = 'http://gitlab_edited.com'
          grafana_integration.token = 'token'

          expect(grafana_integration).to be_valid
          expect(grafana_integration.send(:token)).to eq('token')
          expect(grafana_integration.grafana_url).to eq('http://gitlab_edited.com')
        end
      end
    end
  end
end
