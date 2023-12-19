# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::ScopeMenu, feature_category: :navigation do
  let(:group) { build(:group) }
  let(:user) { group.owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  let(:menu) { described_class.new(context) }

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:extra_attrs) do
      {
        super_sidebar_parent: ::Sidebars::StaticMenu,
        title: group.name,
        avatar: group.avatar_url,
        entity_id: group.id,
        item_id: :group_overview
      }
    end
  end
end
