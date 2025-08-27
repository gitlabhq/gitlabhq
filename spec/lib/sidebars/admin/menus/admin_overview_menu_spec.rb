# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::AdminOverviewMenu, :enable_admin_mode, feature_category: :navigation do
  let(:user) { build_stubbed(:user, :admin) }
  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  it_behaves_like 'Admin menu',
    link: '/admin',
    title: s_('Admin|Overview'),
    icon: 'overview'

  it_behaves_like 'Admin menu with sub menus'

  it_behaves_like 'Admin menu with extra container html options',
    extra_container_html_options: { testid: 'admin-overview-submenu-content' }

  describe 'Menu items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    describe 'Organizations' do
      let(:item_id) { :organizations }

      it { is_expected.not_to be_nil }

      context 'when ui_for_organizations_enabled? is false', :ui_for_organizations_disabled do
        it { is_expected.to be_nil }
      end
    end
  end
end
