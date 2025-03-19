# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe WebIde::Settings::ExtensionMarketplaceMetadataGenerator, feature_category: :web_ide do
  using RSpec::Parameterized::TableSyntax

  let(:marketplace_home_url) { "https://example.com" }
  let(:input_context) do
    {
      requested_setting_names: [:vscode_extension_marketplace_metadata],
      options: options,
      settings: {
        # NOTE: default value of 'vscode_extension_marketplace_metadata' is an empty hash. Include it here to
        #       ensure that it always gets overwritten with the generated value
        vscode_extension_marketplace_metadata: {},
        vscode_extension_marketplace_home_url: marketplace_home_url,
        some_other_existing_setting_that_should_not_be_overwritten: "some context"
      }
    }
  end

  subject(:returned_context) do
    described_class.generate(input_context)
  end

  shared_examples 'extension marketplace settings' do
    it "has the expected settings behavior" do
      if expected_vscode_extension_marketplace_metadata == RuntimeError
        expected_err_msg = "Invalid user.extensions_marketplace_opt_in_status: '#{opt_in_status}'. " \
          "Supported statuses are: [:unset, :enabled, :disabled]."
        expect { returned_context }
          .to raise_error(expected_err_msg)
      else
        expect(returned_context).to eq(
          input_context.deep_merge(
            settings: {
              vscode_extension_marketplace_metadata: expected_vscode_extension_marketplace_metadata
            }
          )
        )
      end
    end
  end

  where(
    :user_exists,
    :opt_in_status,
    :flag_exists,
    :flag_enabled,
    :app_settings_enabled,
    :expected_vscode_extension_marketplace_metadata
  ) do
    # @formatter:off - Turn off RubyMine autoformatting

    # rubocop:disable Layout/LineLength -- Parameterized rows overflow and its better than the alternative
    # user exists | opt_in_status | flag exists | flag_enabled | app_settings_enabled | expected_settings
    false         | :undefined    | false       | :undefined   | true                 | { enabled: false, disabled_reason: :no_user }
    false         | :undefined    | true        | true         | true                 | { enabled: false, disabled_reason: :no_user }
    true          | :unset        | false       | :undefined   | true                 | { enabled: false, disabled_reason: :no_flag }
    true          | :unset        | true        | false        | true                 | { enabled: false, disabled_reason: :instance_disabled }
    true          | :unset        | true        | true         | true                 | { enabled: false, disabled_reason: :opt_in_unset }
    true          | :disabled     | true        | true         | true                 | { enabled: false, disabled_reason: :opt_in_disabled }
    true          | :enabled      | true        | true         | false                | { enabled: false, disabled_reason: :instance_disabled }
    true          | :enabled      | true        | true         | true                 | { enabled: true }
    true          | :invalid      | true        | true         | true                 | RuntimeError
    # rubocop:enable Layout/LineLength

    # @formatter:on
  end

  with_them do
    let(:user_class) do
      stub_const(
        "User",
        Class.new do
          def flipper_id
            "UserStub"
          end
        end
      )
    end

    let(:user) { user_class.new }
    let(:enums) { stub_const('Enums::WebIde::ExtensionsMarketplaceOptInStatus', Class.new) }

    let(:options) do
      options = {}
      options[:user] = user if user_exists
      options[:vscode_extension_marketplace_feature_flag_enabled] = flag_enabled if flag_exists
      options
    end

    before do
      allow(::WebIde::ExtensionMarketplaceOptIn).to receive(:opt_in_status)
        .with(user: user, marketplace_home_url: marketplace_home_url)
        .and_return(opt_in_status.to_s)

      # EE feature has to be stubbed since we run EE code through CE tests
      allow(user).to receive(:enterprise_user?).and_return(false)
      allow(enums).to receive(:statuses).and_return({ unset: :unset, enabled: :enabled, disabled: :disabled })
      allow(::WebIde::ExtensionMarketplace).to receive(:feature_enabled_from_application_settings?)
        .with(user: user)
        .and_return(app_settings_enabled)
    end

    it_behaves_like "extension marketplace settings"
  end

  context "when requested_setting_names does not include vscode_extension_marketplace_metadata" do
    let(:input_context) do
      {
        requested_setting_names: [:some_other_setting],
        options: {}
      }
    end

    it "returns the context unchanged" do
      expect(returned_context).to eq(input_context)
    end
  end
end
