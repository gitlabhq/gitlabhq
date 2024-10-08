# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserProfile::Panel, feature_category: :navigation do
  legacy_menu_classes = [
    Sidebars::UserProfile::Menus::ActivityMenu,
    Sidebars::UserProfile::Menus::GroupsMenu,
    Sidebars::UserProfile::Menus::ContributedProjectsMenu,
    Sidebars::UserProfile::Menus::PersonalProjectsMenu,
    Sidebars::UserProfile::Menus::StarredProjectsMenu,
    Sidebars::UserProfile::Menus::SnippetsMenu,
    Sidebars::UserProfile::Menus::FollowersMenu,
    Sidebars::UserProfile::Menus::FollowingMenu
  ]

  let(:current_user) { build_stubbed(:user) }
  let(:user) { build_stubbed(:user) }

  let(:context) { Sidebars::Context.new(current_user: current_user, container: user) }

  subject { described_class.new(context) }

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel instantiable by the anonymous user'

  describe '#aria_label' do
    specify { expect(subject.aria_label).to eq(s_('UserProfile|User profile navigation')) }
  end

  describe '#super_sidebar_context_header' do
    specify { expect(subject.super_sidebar_context_header).to eq(_('Profile')) }
  end

  it 'does not add legacy menu items' do
    menu_classes = subject.renderable_menus.map(&:class)

    expect(menu_classes).not_to include(*legacy_menu_classes)
  end

  context 'when profile_tabs_vue feature is disabled' do
    before do
      stub_feature_flags(profile_tabs_vue: false)
    end

    it 'add legacy menu items' do
      menu_classes = subject.renderable_menus.map(&:class)

      expect(menu_classes).to include(*legacy_menu_classes)
    end
  end
end
