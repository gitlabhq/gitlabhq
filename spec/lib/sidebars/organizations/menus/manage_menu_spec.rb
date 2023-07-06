# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Organizations::Menus::ManageMenu, feature_category: :navigation do
  let_it_be(:organization) { build(:organization) }
  let_it_be(:user) { build(:user) }
  let_it_be(:context) { Sidebars::Context.new(current_user: user, container: organization) }

  let(:items) { subject.instance_variable_get(:@items) }

  subject { described_class.new(context) }

  it 'has title and sprite_icon' do
    expect(subject.title).to eq(s_("Navigation|Manage"))
    expect(subject.sprite_icon).to eq("users")
  end

  describe 'Menu items' do
    subject { described_class.new(context).renderable_items.find { |e| e.item_id == item_id } }

    describe 'Groups and projects' do
      let(:item_id) { :organization_groups_and_projects }

      it { is_expected.not_to be_nil }
    end
  end
end
