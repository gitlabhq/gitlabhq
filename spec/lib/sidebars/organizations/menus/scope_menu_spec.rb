# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Organizations::Menus::ScopeMenu, feature_category: :navigation do
  let_it_be(:organization_detail) { build(:organization_detail) }
  let_it_be(:organization) { organization_detail.organization }
  let_it_be(:user) { build(:user) }
  let_it_be(:context) { Sidebars::Context.new(current_user: user, container: organization) }

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:menu) { described_class.new(context) }
    let(:extra_attrs) do
      {
        avatar: organization.avatar_url(size: 48),
        entity_id: organization.id,
        super_sidebar_parent: ::Sidebars::StaticMenu,
        item_id: :organization_overview
      }
    end
  end
end
