# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Panel, feature_category: :navigation do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:group) { build_stubbed(:group) }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }

  subject(:groups_panel) { described_class.new(context) }

  describe '#configure_menus' do
    before_all do
      group.add_owner(user)
    end

    it 'adds all standard menus' do
      stub_feature_flags(work_item_planning_view: false)

      groups_panel.configure_menus

      standard_menus = [
        Sidebars::Groups::Menus::GroupInformationMenu,
        Sidebars::Groups::Menus::IssuesMenu,
        Sidebars::Groups::Menus::MergeRequestsMenu,
        Sidebars::Groups::Menus::CiCdMenu,
        Sidebars::Groups::Menus::KubernetesMenu,
        Sidebars::Groups::Menus::PackagesRegistriesMenu,
        Sidebars::Groups::Menus::CustomerRelationsMenu,
        Sidebars::Groups::Menus::SettingsMenu
      ]

      menu_classes = groups_panel.instance_variable_get(:@menus).map(&:class)

      standard_menus.each do |menu_class|
        expect(menu_classes).to include(menu_class)
      end
    end

    context 'when work_item_planning_view feature flag is enabled' do
      before do
        stub_feature_flags(work_item_planning_view: group)
      end

      it 'includes WorkItemsMenu instead of IssuesMenu' do
        groups_panel.configure_menus

        menu_classes = groups_panel.instance_variable_get(:@menus).map(&:class)

        expect(menu_classes).to include(Sidebars::Groups::Menus::WorkItemsMenu)
        expect(menu_classes).not_to include(Sidebars::Groups::Menus::IssuesMenu)
      end
    end

    context 'when observability_sass_features feature flag is enabled' do
      before do
        stub_feature_flags(observability_sass_features: group)
      end

      it 'includes ObservabilityMenu' do
        groups_panel.configure_menus

        menu_classes = groups_panel.instance_variable_get(:@menus).map(&:class)

        expect(menu_classes).to include(Sidebars::Groups::Menus::ObservabilityMenu)
      end

      it 'adds ObservabilityMenu after PackagesRegistriesMenu' do
        groups_panel.configure_menus

        menus = groups_panel.instance_variable_get(:@menus).map(&:class)
        packages_registries_index = menus.index(Sidebars::Groups::Menus::PackagesRegistriesMenu)
        observability_index = menus.index(Sidebars::Groups::Menus::ObservabilityMenu)
        customer_relations_index = menus.index(Sidebars::Groups::Menus::CustomerRelationsMenu)

        expect(packages_registries_index).to be < observability_index
        expect(observability_index).to be < customer_relations_index
      end
    end

    context 'when observability_sass_features feature flag is disabled' do
      before do
        stub_feature_flags(observability_sass_features: false)
      end

      it 'does not include ObservabilityMenu' do
        groups_panel.configure_menus

        menu_classes = groups_panel.instance_variable_get(:@menus).map(&:class)

        expect(menu_classes).not_to include(Sidebars::Groups::Menus::ObservabilityMenu)
      end
    end
  end

  describe '#aria_label' do
    context 'for a subgroup' do
      before do
        allow(group).to receive(:subgroup?).and_return(true)
      end

      it 'returns subgroup navigation label' do
        expect(groups_panel.aria_label).to eq(_('Subgroup navigation'))
      end
    end

    context 'for a root group' do
      before do
        allow(group).to receive(:subgroup?).and_return(false)
      end

      it 'returns group navigation label' do
        expect(groups_panel.aria_label).to eq(_('Group navigation'))
      end
    end
  end
end
