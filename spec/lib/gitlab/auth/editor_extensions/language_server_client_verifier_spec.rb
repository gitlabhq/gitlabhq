# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::EditorExtensions::LanguageServerClientVerifier, feature_category: :editor_extensions do
  let_it_be(:user, freeze: true) { create(:user) }

  let(:request) do
    instance_double(ActionDispatch::Request, {
      headers: ActionDispatch::Http::Headers.from_hash(headers)
    })
  end

  describe '#execute' do
    subject { described_class.new(current_user: user, request: request).execute }

    shared_examples 'client verification was successful' do |params|
      let(:headers) { params.fetch(:headers) }

      it { expect(subject).to be_success }
    end

    shared_examples 'client verification was unsuccessful' do |params|
      let(:headers) { params.fetch(:headers) }

      it { expect(subject).to be_error.and have_attributes(reason: params[:reason]) }
    end

    shared_examples 'allowed clients were successful' do
      context 'with a different client' do
        it_behaves_like 'client verification was successful', headers: {
          'HTTP_USER_AGENT' => 'my-cool-app 1.2.3'
        }
      end

      context 'with a matching language server client' do
        it_behaves_like 'client verification was successful', headers: {
          'HTTP_USER_AGENT' => 'gitlab-language-server 2.0.0',
          'HTTP_X_GITLAB_LANGUAGE_SERVER_VERSION' => '2.0.0'
        }
      end

      context 'with an updated language server client' do
        it_behaves_like 'client verification was successful', headers: {
          'HTTP_USER_AGENT' => 'gitlab-language-server 999.99.9',
          'HTTP_X_GITLAB_LANGUAGE_SERVER_VERSION' => '999.99.9'
        }
      end
    end

    shared_examples 'restricted clients were unsuccessful' do
      context 'with an obsolete language server client' do
        it_behaves_like 'client verification was unsuccessful',
          reason: :instance_requires_newer_client,
          headers: {
            'HTTP_USER_AGENT' => 'code-completions-language-server-experiment (gl-visual-studio-extension:1.0.0.0)'
          }
      end

      context 'with an outdated language server client' do
        it_behaves_like 'client verification was unsuccessful',
          reason: :instance_requires_newer_client,
          headers: {
            'HTTP_USER_AGENT' => 'gitlab-language-server 1.2.3',
            'HTTP_X_GITLAB_LANGUAGE_SERVER_VERSION' => '1.2.3'
          }
      end
    end

    shared_examples 'the enable_language_server_restrictions application setting is disabled' do
      include_examples 'allowed clients were successful'

      context 'with an obsolete language server client' do
        it_behaves_like 'client verification was successful', headers: {
          'HTTP_USER_AGENT' => 'code-completions-language-server-experiment (gl-visual-studio-extension:1.0.0.0)'
        }
      end

      context 'with an outdated language server client' do
        it_behaves_like 'client verification was successful', headers: {
          'HTTP_USER_AGENT' => 'gitlab-language-server 1.2.3',
          'HTTP_X_GITLAB_LANGUAGE_SERVER_VERSION' => '1.2.3'
        }
      end
    end

    shared_context 'with language server restrictions disabled' do
      before do
        allow(Gitlab::CurrentSettings.current_application_settings).to receive_messages(
          enable_language_server_restrictions: false,
          minimum_language_server_version: '2.0.0')
      end
    end

    shared_context 'with language server restrictions enabled' do
      before do
        allow(Gitlab::CurrentSettings.current_application_settings).to receive_messages(
          enable_language_server_restrictions: true,
          minimum_language_server_version: '2.0.0')
      end
    end

    context 'with the enforce_language_server_version feature flag disabled' do
      before do
        stub_feature_flags(enforce_language_server_version: false)
        allow(Gitlab::CurrentSettings.current_application_settings).to receive(:gitlab_dedicated_instance?)
          .and_return(false)
      end

      context 'with the enable_language_server_restrictions application setting disabled' do
        include_context 'with language server restrictions disabled'
        it_behaves_like 'the enable_language_server_restrictions application setting is disabled'
      end

      context 'with the enable_language_server_restrictions application setting enabled' do
        include_context 'with language server restrictions enabled'
        it_behaves_like 'the enable_language_server_restrictions application setting is disabled'
      end
    end

    context 'with the enforce_language_server_version feature flag enabled' do
      before do
        stub_feature_flags(enforce_language_server_version: true)
        allow(Gitlab::CurrentSettings.current_application_settings).to receive(:gitlab_dedicated_instance?)
          .and_return(false)
      end

      context 'with the enable_language_server_restrictions application setting disabled' do
        include_context 'with language server restrictions disabled'
        it_behaves_like 'the enable_language_server_restrictions application setting is disabled'
      end

      context 'with the enable_language_server_restrictions application setting enabled' do
        include_context 'with language server restrictions enabled'
        it_behaves_like 'allowed clients were successful'
        it_behaves_like 'restricted clients were unsuccessful'
      end
    end

    context 'on a dedicated instance' do
      before do
        stub_feature_flags(enforce_language_server_version: false)
        allow(Gitlab::CurrentSettings.current_application_settings).to receive(:gitlab_dedicated_instance?)
          .and_return(true)
      end

      context 'with the enable_language_server_restrictions application setting disabled' do
        include_context 'with language server restrictions disabled'
        it_behaves_like 'the enable_language_server_restrictions application setting is disabled'
      end

      context 'with the enable_language_server_restrictions application setting enabled' do
        include_context 'with language server restrictions enabled'
        it_behaves_like 'allowed clients were successful'
        it_behaves_like 'restricted clients were unsuccessful'
      end
    end
  end
end
