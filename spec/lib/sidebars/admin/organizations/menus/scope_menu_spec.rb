# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FactoryBot/AvoidCreate -- render? depends on persisted organization membership
RSpec.describe Sidebars::Admin::Organizations::Menus::ScopeMenu, feature_category: :navigation do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:owner) { create(:user, owner_of: organization) }
  let_it_be(:regular_user) { create(:user) }

  let(:user) { owner }
  let(:context) do
    Sidebars::Context.new(current_user: user, container: nil, current_organization: organization)
  end

  subject(:menu) { described_class.new(context) }

  it 'is titled with the organization name' do
    expect(menu.title).to eq(organization.name)
  end

  it 'links to the organization admin root' do
    # rubocop:disable Gitlab/AvoidOrganizationUrlRoutes -- We only want to generate org-scoped path here
    expected = Gitlab::Routing.url_helpers.organization_admin_root_path(organization)
    # rubocop:enable Gitlab/AvoidOrganizationUrlRoutes

    expect(menu.link).to eq(expected)
  end

  it 'is active on the organization admin dashboard' do
    expect(menu.active_routes).to eq({ controller: 'admin/organizations/dashboard' })
  end

  describe '#serialize_as_menu_item_args' do
    it 'includes the entity details and hoists to the static menu' do
      expect(menu.serialize_as_menu_item_args).to include(
        entity_id: organization.id,
        avatar: organization.avatar_url(size: 48),
        item_id: :organization_admin_scope,
        super_sidebar_parent: ::Sidebars::StaticMenu
      )
    end
  end

  describe '#render?' do
    it { is_expected.to be_render }

    context 'when the user cannot access the organization admin area' do
      let(:user) { regular_user }

      it { is_expected.not_to be_render }
    end

    context 'when there is no user' do
      let(:user) { nil }

      it { is_expected.not_to be_render }
    end
  end
end
# rubocop:enable RSpec/FactoryBot/AvoidCreate
