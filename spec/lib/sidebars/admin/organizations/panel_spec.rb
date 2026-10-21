# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Organizations::Panel, feature_category: :navigation do
  let_it_be(:organization) { build(:organization) }
  let_it_be(:user) { build(:admin) }

  let(:context) do
    Sidebars::Context.new(current_user: user, container: nil, current_organization: organization)
  end

  subject(:panel) { described_class.new(context) }

  describe '#aria_label' do
    it 'returns the correct aria label' do
      expect(panel.aria_label).to eq(s_('Organization|Organization administration'))
    end
  end

  describe '#super_sidebar_context_header' do
    it 'returns the correct header' do
      expect(panel.super_sidebar_context_header).to eq(s_('Organization|Organization administration'))
    end
  end

  describe 'scope menu' do
    it 'is titled with the organization name' do
      expect(panel.scope_menu.title).to eq(organization.name)
    end

    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- menus only render for a user who can admin the organization
    context 'when the user can access the organization admin area' do
      let_it_be(:organization) { create(:organization) }
      let_it_be(:user) { create(:user, owner_of: organization) }

      it 'appears in the rendered sidebar' do
        item_ids = panel.super_sidebar_menu_items.map { |item| item[:id] }

        expect(item_ids).to include(:organization_admin_scope)
      end
    end
    # rubocop:enable RSpec/FactoryBot/AvoidCreate
  end

  it 'includes the overview menu' do
    expect(panel.instance_variable_get(:@menus).map(&:class))
      .to include(Sidebars::Admin::Organizations::Menus::OverviewMenu)
  end

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel instantiable by the anonymous user'
end
