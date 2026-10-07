# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::ClientIdentity, feature_category: :application_instrumentation do
  let(:chrome_user_agent) do
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) ' \
      'Chrome/129.0.0.0 Safari/537.36'
  end

  describe '.from_headers' do
    using RSpec::Parameterized::TableSyntax

    where(:type_header, :name_header, :expected_type, :expected_name) do
      'mobile'         | 'gitlab-mobile-ios'        | 'mobile'      | 'gitlab-mobile-ios'
      'MOBILE'         | 'GitLab-Mobile-Android'    | 'mobile'      | 'gitlab-mobile-android'
      'web_browser'    | nil                        | 'browser'     | nil
      'browser'        | 'gitlab-duo-workflow'      | 'browser'     | nil
      'web'            | 'chrome'                   | 'browser'     | 'chrome'
      nil              | 'Firefox'                  | 'browser'     | 'firefox'
      'node-websocket' | 'Duo CLI'                  | 'cli'         | 'duo-cli'
      'node-websocket' | 'IntelliJ IDEA'            | 'ide'         | 'jetbrains'
      nil              | 'gitlab-jetbrains-plugin'  | 'ide'         | 'jetbrains'
      nil              | 'GitLab Duo'               | 'ide'         | 'jetbrains'
      nil              | 'gitlab-duo-cli'           | 'cli'         | 'duo-cli'
      'duo_cli'        | 'gitlab-duo-workflow'      | 'cli'         | nil
      'mobile'         | 'vscode'                   | 'mobile'      | nil
      nil              | 'Visual Studio Code'       | 'ide'         | 'vscode'
      nil              | 'gitlab-duo-workflow'      | nil           | nil
      'ide'            | 'Some Unknown Editor'      | 'ide'         | nil
      'spaceship'      | nil                        | nil           | nil
      nil              | nil                        | nil           | nil
    end

    with_them do
      subject(:identity) { described_class.from_headers(type_header, name_header) }

      it 'keeps only allowlisted values' do
        if expected_type
          expect(identity).to have_attributes(type: expected_type, name: expected_name)
        else
          expect(identity).to be_nil
        end
      end
    end
  end

  describe '.from_user_agent' do
    using RSpec::Parameterized::TableSyntax

    where(:user_agent, :expected_type, :expected_name) do
      'Mozilla/5.0 (Macintosh) AppleWebKit/537.36 Chrome/129.0.0.0 Safari/537.36' | 'browser' | 'chrome'
      'Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0' | 'browser' | 'firefox'
      'Mozilla/5.0 (Macintosh) AppleWebKit/605.1.15 Version/17.6 Safari/605.1.15' | 'browser' | 'safari'
      'Mozilla/5.0 (Windows) AppleWebKit/537.36 Chrome/129.0.0.0 Safari/537.36 Edg/129.0.0.0' | 'browser' | 'edge'
      'Mozilla/5.0 AppleWebKit/537.36 Chrome/128.0.0.0 Electron/32.1.2 Safari/537.36' | 'browser' | 'electron'
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)' | 'browser' | nil
      'vs-code-gitlab-workflow/3.11.1 VSCode/1.52.1 Node.js/12.14.1 (darwin; x64)' | 'ide' | 'vscode'
      'gitlab-jetbrains-plugin/0.0.1 intellij-idea/2021.2.4'                        | 'ide'    | 'jetbrains'
      'IntelliJ-GitLab-Plugin PhpStorm/PS-232.6734.11'                              | 'ide'    | 'jetbrains-bundled'
      'code-completions-language-server-experiment (gl-visual-studio-extension:1.0.0.0;)' | 'ide' | 'visual-studio'
      'code-completions-language-server-experiment (Neovim:0.9.0; gitlab.vim (v0.1.0);)'  | 'ide' | 'neovim'
      'glab/v1.25.3 (built 2023-02-16), darwin' | 'cli' | 'glab'
      'gitlab-runner 17.0.0 (17-0-stable; go1.22; linux/amd64)' | 'system' | 'gitlab-rails'
      'git/2.45.0' | 'system' | 'gitlab-rails'
      'Agent-Flow-via-GitLab-Workhorse' | 'system' | 'gitlab-rails'
      'GitLabMobile/1.2.0 (iOS 26.0.1; build 45)' | 'api' | nil
      'python-requests/2.31'                                                        | 'api'    | nil
      nil                                                                           | 'api'    | nil
    end

    with_them do
      it 'falls back to the User-Agent' do
        expect(described_class.from_user_agent(user_agent))
          .to have_attributes(type: expected_type, name: expected_name)
      end
    end

    it 'keeps the browser type for a User-Agent the browser gem refuses to parse' do
      user_agent = "Mozilla/5.0 #{'x' * 3000}"

      expect(described_class.from_user_agent(user_agent)).to have_attributes(type: 'browser', name: nil)
    end
  end

  describe '.from_request' do
    let(:request) { ActionDispatch::Request.new(env) }

    context 'with client headers' do
      let(:env) do
        Rack::MockRequest.env_for('/').merge(
          'HTTP_X_GITLAB_CLIENT_TYPE' => 'mobile',
          'HTTP_X_GITLAB_CLIENT_NAME' => 'gitlab-mobile-ios',
          'HTTP_USER_AGENT' => chrome_user_agent
        )
      end

      it 'prefers the headers over the User-Agent' do
        expect(described_class.from_request(request)).to have_attributes(type: 'mobile', name: 'gitlab-mobile-ios')
      end
    end

    context 'with a browser type header and no name' do
      let(:env) do
        Rack::MockRequest.env_for('/').merge(
          'HTTP_X_GITLAB_CLIENT_TYPE' => 'browser',
          'HTTP_USER_AGENT' => chrome_user_agent
        )
      end

      it 'names the client after the browser family' do
        expect(described_class.from_request(request)).to have_attributes(type: 'browser', name: 'chrome')
      end
    end

    context 'with the headers Workhorse forwards for a browser session' do
      let(:env) do
        Rack::MockRequest.env_for('/').merge(
          'HTTP_X_GITLAB_CLIENT_TYPE' => 'browser',
          'HTTP_X_GITLAB_CLIENT_NAME' => 'chrome',
          'HTTP_USER_AGENT' => 'Agent-Flow-via-GitLab-Workhorse'
        )
      end

      it 'keeps the forwarded browser family' do
        expect(described_class.from_request(request)).to have_attributes(type: 'browser', name: 'chrome')
      end
    end

    context 'with a browser type header and a name of another type' do
      let(:env) do
        Rack::MockRequest.env_for('/').merge(
          'HTTP_X_GITLAB_CLIENT_TYPE' => 'browser',
          'HTTP_X_GITLAB_CLIENT_NAME' => 'gitlab-duo-workflow',
          'HTTP_USER_AGENT' => chrome_user_agent
        )
      end

      it 'drops the name and uses the browser family' do
        expect(described_class.from_request(request)).to have_attributes(type: 'browser', name: 'chrome')
      end
    end

    context 'without client headers' do
      let(:env) { Rack::MockRequest.env_for('/').merge('HTTP_USER_AGENT' => chrome_user_agent) }

      it 'uses the User-Agent' do
        expect(described_class.from_request(request)).to have_attributes(type: 'browser', name: 'chrome')
      end
    end
  end

  describe 'with invalid UTF-8 in the inputs' do
    let(:invalid) { (+"\xff mobile").force_encoding(Encoding::UTF_8) }

    it 'does not raise and treats the value as unrecognised' do
      expect(described_class.from_headers(invalid, invalid)).to be_nil
      expect(described_class.from_user_agent(invalid)).to eq(described_class::API)
    end

    it 'does not raise when the browser family is read from an invalid User-Agent' do
      user_agent = (+"Mozilla/5.0 \xff Chrome/129.0.0.0").force_encoding(Encoding::UTF_8)

      expect(described_class.from_user_agent(user_agent)).to have_attributes(type: 'browser', name: 'chrome')
    end
  end

  describe '.current' do
    it 'is nil without an application context' do
      expect(described_class.current).to be_nil
    end

    it 'reads the application context' do
      Gitlab::ApplicationContext.with_context(client_type: 'mobile', client_name: 'gitlab-mobile-ios') do
        expect(described_class.current).to have_attributes(type: 'mobile', name: 'gitlab-mobile-ios')
      end
    end
  end
end
