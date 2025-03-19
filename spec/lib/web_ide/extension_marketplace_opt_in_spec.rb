# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe WebIde::ExtensionMarketplaceOptIn, feature_category: :web_ide do
  using RSpec::Parameterized::TableSyntax

  let(:user_class) do
    stub_const("User", Struct.new(
      :extensions_marketplace_opt_in_status,
      :extensions_marketplace_opt_in_url,
      keyword_init: true
    ))
  end

  let(:user) do
    User.new(
      extensions_marketplace_opt_in_status: opt_in_status,
      extensions_marketplace_opt_in_url: opt_in_url
    )
  end

  describe '.opt_in_status' do
    subject(:opt_in_status) do
      described_class.opt_in_status(user: user, marketplace_home_url: marketplace_home_url)
    end

    where(:opt_in_status, :opt_in_url, :marketplace_home_url, :expectation) do
      'enabled'  | 'https://example.com'  | nil                    | 'unset'
      'enabled'  | 'https://example.com'  | 'https://open-vsx.org' | 'unset'
      'enabled'  | 'https://open-vsx.org' | 'https://open-vsx.org' | 'enabled'
      'disabled' | 'https://open-vsx.org' | 'https://open-vsx.org' | 'disabled'
      'unset'    | 'https://open-vsx.org' | 'https://open-vsx.org' | 'unset'
    end

    with_them do
      it { is_expected.to eq(expectation) }
    end
  end

  describe '.enabled?' do
    subject(:enabled) do
      described_class.enabled?(user: user, marketplace_home_url: marketplace_home_url)
    end

    where(:opt_in_status, :opt_in_url, :marketplace_home_url, :expectation) do
      'enabled'  | 'https://open-vsx.org' | nil | false
      'enabled'  | 'https://open-vsx.org' | 'https://example.com' | false
      'enabled'  | 'https://example.com'  | 'https://example.com' | true
      'disabled' | 'https://example.com'  | 'https://example.com' | false
      'unset'    | 'https://example.com'  | 'https://example.com' | false
    end

    with_them do
      it { is_expected.to eq(expectation) }
    end
  end

  describe '.params' do
    subject(:params) do
      described_class.params(enabled: enabled, marketplace_home_url: marketplace_home_url)
    end

    where(:enabled, :marketplace_home_url, :expected_status) do
      true | 'https://example.com' | 'enabled'
      false | 'https://example.com' | 'disabled'
    end

    with_them do
      it 'returns params for updating user_preferences' do
        is_expected.to match(
          extensions_marketplace_opt_in_status: expected_status,
          extensions_marketplace_opt_in_url: marketplace_home_url
        )
      end
    end
  end
end
