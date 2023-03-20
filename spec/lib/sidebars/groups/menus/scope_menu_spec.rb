# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::ScopeMenu, feature_category: :navigation do
  let(:group) { build(:group) }
  let(:user) { group.owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  let(:menu) { described_class.new(context) }

  describe '#extra_nav_link_html_options' do
    subject { menu.extra_nav_link_html_options }

    specify { is_expected.to match(hash_including(class: 'context-header has-tooltip', title: context.group.name)) }
  end

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:extra_attrs) do
      {
        sprite_icon: 'group',
        super_sidebar_parent: ::Sidebars::StaticMenu,
        title: _('Group overview'),
        item_id: :group_overview
      }
    end
  end
end
