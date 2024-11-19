# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Organizations::Menus::ManageMenu, feature_category: :navigation do
  let(:organization) { build(:organization) }
  let(:user) { build(:user) }
  let(:context) { Sidebars::Context.new(current_user: user, container: organization) }

  subject(:menu) { described_class.new(context) }

  it 'has title and sprite_icon' do
    expect(menu.title).to eq(s_("Navigation|Manage"))
    expect(menu.sprite_icon).to eq("users")
  end

  describe 'Menu items' do
    subject(:item) { menu.renderable_items.find { |e| e.item_id == item_id } }

    describe 'Activity' do
      let(:item_id) { :organization_activity }

      it { is_expected.not_to be_nil }
    end

    describe 'Groups and projects' do
      let(:item_id) { :organization_groups_and_projects }

      it { is_expected.not_to be_nil }
    end

    describe 'Users' do
      let(:item_id) { :organization_users }

      context 'when current user has permissions' do
        before do
          create(:organization_owner, user: user, organization: organization) # rubocop: disable RSpec/FactoryBot/AvoidCreate -- does not work with build_stubbed
        end

        it { is_expected.not_to be_nil }
      end

      context 'when current user does not have permissions' do
        it { is_expected.to be_nil }
      end
    end
  end
end
