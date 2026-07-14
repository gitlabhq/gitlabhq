# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Menus::ImportHistoryMenu, feature_category: :navigation do
  let(:user) { build_stubbed(:user) }
  let(:context) { Sidebars::Context.new(current_user: current_user, container: nil) }

  describe '#render?' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.new(context).render? }

    where(:current_user, :bulk_import_enabled, :result) do
      nil  | true  | false
      user | false | false
      user | true  | true
    end

    with_them do
      before do
        stub_application_setting(bulk_import_enabled: bulk_import_enabled)
      end

      it { is_expected.to eq(result) }
    end
  end
end
