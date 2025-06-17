# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::EditorExtensions::LanguageServerClient, feature_category: :editor_extensions do
  describe '#lsp_client?' do
    subject { described_class.new(client_version: client_version, user_agent: user_agent) }

    context 'with no client version' do
      let(:client_version) { nil }

      context 'with no user agent' do
        let(:user_agent) { nil }

        it { is_expected.not_to be_lsp_client }
        it { is_expected.to have_attributes(version: eq(Gem::Version.new('0.1.0'))) }
      end

      context 'with an outdated user agent' do
        let(:user_agent) do
          'code-completions-language-server-experiment (gl-visual-studio-extension:1.0.0.0; arch:X64;)'
        end

        it { is_expected.to be_lsp_client.and have_attributes(version: eq(Gem::Version.new('0.1.0'))) }
      end

      context 'with an unrecognized user agent' do
        let(:user_agent) { 'unknown-agent 1.0.0' }

        it { is_expected.not_to be_lsp_client }
        it { is_expected.to have_attributes(version: eq(Gem::Version.new('0.1.0'))) }
      end
    end

    context 'with invalid client version and an outdated user agent' do
      let(:client_version) { 'a.b.c' }
      let(:user_agent) { 'code-completions-language-server-experiment (gl-visual-studio-extension:1.0.0.0; arch:X64;)' }

      it { is_expected.to be_lsp_client.and have_attributes(version: eq(Gem::Version.new('0.1.0'))) }
    end

    context 'with valid client version and a recognized user agent' do
      let(:client_version) { '1.0.0' }
      let(:user_agent) { 'gitlab-language-server 1.0.0' }

      it { is_expected.to be_lsp_client.and have_attributes(version: eq(Gem::Version.new('1.0.0'))) }
    end

    context 'with valid client version and no user agent' do
      let(:client_version) { '1.0.0' }
      let(:user_agent) { nil }

      it { is_expected.to be_lsp_client.and have_attributes(version: eq(Gem::Version.new('1.0.0'))) }
    end
  end
end
