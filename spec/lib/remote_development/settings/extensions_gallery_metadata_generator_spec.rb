# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Settings::ExtensionsGalleryMetadataGenerator, :rd_fast, feature_category: :remote_development do
  using RSpec::Parameterized::TableSyntax

  let(:input_value) do
    {
      options: options,
      settings: {
        # NOTE: default value of 'vscode_extensions_gallery_metadata' is an empty hash. Include it here to
        #       ensure that it always gets overwritten with the generated value
        vscode_extensions_gallery_metadata: {},
        some_other_existing_setting_that_should_not_be_overwritten: "some value"
      }
    }
  end

  subject(:returned_value) do
    described_class.generate(input_value)
  end

  shared_examples 'extensions marketplace settings' do
    it "has the expected settings behavior" do
      if expected_vscode_extensions_gallery_metadata == RuntimeError
        expected_err_msg = "Invalid user.extensions_marketplace_opt_in_status: '#{opt_in_status}'. " \
          "Supported statuses are: [:unset, :enabled, :disabled]."
        expect { returned_value }
          .to raise_error(expected_err_msg)
      else
        expect(returned_value).to eq(
          input_value.deep_merge(
            settings: {
              vscode_extensions_gallery_metadata: expected_vscode_extensions_gallery_metadata
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
    :expected_vscode_extensions_gallery_metadata
  ) do
    # @formatter:off - Turn off RubyMine autoformatting

    # user exists | opt_in_status | flag exists | flag_enabled | expected_settings
    false         | :undefined    | false       | :undefined   | { enabled: false, disabled_reason: :no_user }
    false         | :undefined    | true        | true         | { enabled: false, disabled_reason: :no_user }
    true          | :unset        | false       | :undefined   | { enabled: false, disabled_reason: :no_flag }
    true          | :unset        | true        | false        | { enabled: false, disabled_reason: :instance_disabled }
    true          | :unset        | true        | true         | { enabled: false, disabled_reason: :opt_in_unset }
    true          | :disabled     | true        | true         | { enabled: false, disabled_reason: :opt_in_disabled }
    true          | :enabled      | true        | true         | { enabled: true }
    true          | :invalid      | true        | true         | RuntimeError

    # @formatter:on
  end

  with_them do
    let(:user) { create(:user) }

    let(:options) do
      options = {}
      options[:user] = user if user_exists
      options[:vscode_extensions_marketplace_feature_flag_enabled] = flag_enabled if flag_exists
      options
    end

    before do
      allow(user).to receive(:extensions_marketplace_opt_in_status) { opt_in_status.to_s }
    end

    it_behaves_like "extensions marketplace settings"
  end
end
