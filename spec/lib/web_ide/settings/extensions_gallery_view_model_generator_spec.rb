# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe WebIde::Settings::ExtensionsGalleryViewModelGenerator, feature_category: :web_ide do
  using RSpec::Parameterized::TableSyntax

  let(:user_class) { stub_const('User', Class.new) }
  let(:user) { user_class.new }
  let(:requested_setting_names) { [:vscode_extensions_gallery_view_model] }
  let(:vscode_extensions_gallery) { { item_url: 'https://example.com/vscode/is/cooler/than/rubymine' } }
  let(:vscode_extensions_gallery_metadata) { { enabled: true } }
  let(:context) do
    {
      requested_setting_names: requested_setting_names,
      settings: {
        vscode_extensions_gallery: vscode_extensions_gallery,
        vscode_extensions_gallery_metadata: vscode_extensions_gallery_metadata
      },
      options: {
        user: user
      }
    }
  end

  before do
    # why: Stubs necessary for fast_spec_helper. See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167495#note_2290309350
    # The `spec/lib/web_ide/extensions_marketplace_spec.rb` covers everything in integration, so we should be good.
    allow(::Gitlab::Routing).to receive_message_chain(:url_helpers, :profile_preferences_url)
      .with(anchor: 'integrations')
      .and_return('http://gdk.test/profile_preferences_url#integrations')

    allow(::Gitlab::Routing).to receive_message_chain(:url_helpers, :help_page_url)
      .with('user/project/web_ide/_index.md', anchor: 'extension-marketplace')
      .and_return('http://gdk.test/help_url')
  end

  describe '.generate' do
    subject(:settings_result) do
      described_class.generate(context).dig(:settings, :vscode_extensions_gallery_view_model)
    end

    it 'by default, setting is enabled with vscode_settings' do
      expect(settings_result).to eq({ enabled: true, vscode_settings: vscode_extensions_gallery })
    end

    context 'when settings name is not requested' do
      let(:requested_setting_names) { [] }

      it 'setting is not set' do
        expect(settings_result).to be_nil
      end
    end

    context 'when metadata is disabled' do
      where(:disabled_reason, :expectation) do
        :instance_disabled | {}
        :opt_in_unset      | { user_preferences_url: 'http://gdk.test/profile_preferences_url#integrations' }
        :opt_in_disabled   | { user_preferences_url: 'http://gdk.test/profile_preferences_url#integrations' }
      end

      with_them do
        let(:vscode_extensions_gallery_metadata) { { enabled: false, disabled_reason: disabled_reason } }

        it 'setting is disabled with attributes for view' do
          expect(settings_result).to match({
            enabled: false,
            reason: disabled_reason,
            help_url: 'http://gdk.test/help_url'
          }.merge(expectation))
        end
      end
    end
  end
end
