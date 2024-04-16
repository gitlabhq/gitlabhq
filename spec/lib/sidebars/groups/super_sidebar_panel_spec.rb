# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::SuperSidebarPanel, feature_category: :navigation do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, owners: user) }

  let(:context) do
    Sidebars::Groups::Context.new(
      current_user: user,
      container: group,
      is_super_sidebar: true,
      # Turn features off that do not add/remove menu items
      show_promotions: false,
      show_discover_group_security: false
    )
  end

  subject { described_class.new(context) }

  it 'implements #super_sidebar_context_header' do
    expect(subject.super_sidebar_context_header).to eq(_('Group'))
  end

  describe '#renderable_menus' do
    let(:category_menu) do
      [
        Sidebars::StaticMenu,
        Sidebars::Groups::SuperSidebarMenus::ManageMenu,
        Sidebars::Groups::SuperSidebarMenus::PlanMenu,
        Sidebars::Groups::SuperSidebarMenus::CodeMenu,
        Sidebars::Groups::SuperSidebarMenus::BuildMenu,
        Sidebars::Groups::SuperSidebarMenus::SecureMenu,
        Sidebars::Groups::SuperSidebarMenus::DeployMenu,
        Sidebars::Groups::SuperSidebarMenus::OperationsMenu,
        Sidebars::Groups::SuperSidebarMenus::AnalyzeMenu,
        Sidebars::UncategorizedMenu,
        Sidebars::Groups::Menus::SettingsMenu
      ]
    end

    it "is exposed as a renderable menu" do
      expect(subject.instance_variable_get(:@menus).map(&:class)).to eq(category_menu)
    end
  end

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel with all menu_items categorized'
  it_behaves_like 'a panel instantiable by the anonymous user'
end
