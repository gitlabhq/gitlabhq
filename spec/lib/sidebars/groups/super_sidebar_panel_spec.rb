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

    before do
      allow(Feature).to receive(:enabled?).and_call_original
      allow(Feature).to receive(:enabled?).with(:observability_sass_features, any_args).and_return(false)
    end

    it "is exposed as a renderable menu" do
      expect(subject.instance_variable_get(:@menus).map(&:class)).to include(*category_menu)
    end
  end

  describe '#configure_menus' do
    context 'when observability_sass_features feature flag is enabled' do
      before do
        stub_feature_flags(observability_sass_features: group)
        # Prevent circular reference in route lookups
        allow(Feature).to receive(:enabled?).and_call_original
      end

      it 'includes ObservabilityMenu' do
        menu_classes = subject.instance_variable_get(:@menus).map(&:class)
        expect(menu_classes).to include(Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu)
      end

      it 'adds ObservabilityMenu after AnalyzeMenu' do
        menus = subject.instance_variable_get(:@menus).map(&:class)
        analyze_index = menus.index(Sidebars::Groups::SuperSidebarMenus::AnalyzeMenu)
        observability_index = menus.index(Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu)

        expect(analyze_index).to be < observability_index
      end

      it 'evaluates feature flag against the correct group context' do
        allow_next_instance_of(Sidebars::Menu) do |instance|
          allow(instance).to receive(:title).and_return("Menu Title")
        end
        expect(::Feature).to receive(:enabled?).with(:observability_sass_features, group).and_return(true)

        subject.configure_menus
      end

      it 'adds the ObservabilityMenu instance to menus' do
        observability_menu = subject.instance_variable_get(:@menus).find do |menu|
          menu.is_a?(Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu)
        end

        expect(observability_menu).to be_an_instance_of(Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu)
      end
    end

    context 'when observability_sass_features feature flag is disabled' do
      before do
        stub_feature_flags(observability_sass_features: false)
      end

      it 'does not include ObservabilityMenu' do
        menu_classes = subject.instance_variable_get(:@menus).map(&:class)
        expect(menu_classes).not_to include(Sidebars::Groups::SuperSidebarMenus::ObservabilityMenu)
      end
    end
  end

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel with all menu_items categorized'
  it_behaves_like 'a panel instantiable by the anonymous user'
end
