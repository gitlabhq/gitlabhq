# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebIde::DefaultOauthApplication, feature_category: :web_ide do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:oauth_application) { create(:oauth_application, owner: nil) }

  describe '#feature_enabled?' do
    where(:vscode_web_ide, :expectation) do
      [
        [ref(:current_user), true],
        [false, false]
      ]
    end

    with_them do
      it 'returns the expected value' do
        stub_feature_flags(vscode_web_ide: vscode_web_ide)

        expect(described_class.feature_enabled?(current_user)).to be(expectation)
      end
    end
  end

  describe '#oauth_application' do
    it 'returns web_ide_oauth_application from application_settings' do
      expect(described_class.oauth_application).to be_nil

      stub_application_setting({ web_ide_oauth_application: oauth_application })

      expect(described_class.oauth_application).to be(oauth_application)
    end
  end

  describe '#oauth_callback_url' do
    it 'returns route URL for oauth callback' do
      expect(described_class.oauth_callback_url).to eq(Gitlab::Routing.url_helpers.ide_oauth_redirect_url)
    end
  end

  describe '#oauth_application_callback_urls' do
    it 'returns application callback URL' do
      expected_result = [oauth_application.redirect_uri]

      stub_application_setting({ web_ide_oauth_application: oauth_application })

      expect(described_class.oauth_application_callback_urls).to match_array(expected_result)
    end

    context 'with multiple oauth callback URLs' do
      let(:redirect_uri_1) { "http://example1.test/oauth-redirect" }
      let(:redirect_uri_2) { "http://example2.test/oauth-redirect" }

      it 'supports multiple OAuth callback URLs' do
        oauth_application.redirect_uri = "#{redirect_uri_1}\n#{redirect_uri_2}"
        expected_result = [redirect_uri_1, redirect_uri_2]
        stub_application_setting({ web_ide_oauth_application: oauth_application })
        expect(described_class.oauth_application_callback_urls).to match_array(expected_result)
      end

      it 'returns unique URL origins' do
        oauth_application.redirect_uri = "#{redirect_uri_1}\n #{redirect_uri_1}"
        expected_result = [redirect_uri_1]
        stub_application_setting({ web_ide_oauth_application: oauth_application })
        expect(described_class.oauth_application_callback_urls).to match_array(expected_result)
      end
    end
  end

  describe '#ensure_oauth_application!' do
    it 'if web_ide_oauth_application already exists, does nothing' do
      expect(application_settings).not_to receive(:lock!)
      expect(::Doorkeeper::Application).not_to receive(:new)

      stub_application_setting({ web_ide_oauth_application: oauth_application })

      described_class.ensure_oauth_application!
    end

    it 'if web_ide_oauth_application created while locked, does nothing' do
      expect(application_settings).to receive(:lock!) do
        stub_application_setting({ web_ide_oauth_application: oauth_application })
      end
      expect(::Doorkeeper::Application).not_to receive(:new)
      expect(::Gitlab::CurrentSettings).not_to receive(:expire_current_application_settings)

      described_class.ensure_oauth_application!
    end

    it 'creates web_ide_oauth_application' do
      expect(application_settings).to receive(:transaction).and_call_original
      expect(::Doorkeeper::Application).to receive(:new).and_call_original
      expect(::Gitlab::CurrentSettings).to receive(:expire_current_application_settings).and_call_original

      expect(application_settings.web_ide_oauth_application).to be_nil

      described_class.ensure_oauth_application!

      result = application_settings.web_ide_oauth_application
      expect(result).not_to be_nil
      expect(result).to have_attributes(
        name: 'GitLab Web IDE',
        redirect_uri: described_class.oauth_callback_url,
        scopes: ['api'],
        trusted: true,
        confidential: false
      )
    end
  end

  describe '#reset_oauth_application_settings' do
    it 'resets oauth application settings to original' do
      mock_bad_oauth_application = oauth_application
      mock_bad_oauth_application["confidential"] = true
      mock_bad_oauth_application["trusted"] = false

      stub_application_setting({ web_ide_oauth_application: mock_bad_oauth_application })

      described_class.reset_oauth_application_settings

      expect(oauth_application).to have_attributes(
        name: 'GitLab Web IDE',
        redirect_uri: described_class.oauth_callback_url,
        scopes: ['api'],
        trusted: true,
        confidential: false
      )
    end
  end

  def application_settings
    ::Gitlab::CurrentSettings.current_application_settings
  end
end
