# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::GroupInformationMenu do
  let_it_be(:owner) { create(:user) }
  let_it_be(:root_group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:group) { root_group }
  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }

  describe '#title' do
    subject { described_class.new(context).title }

    context 'when group is a root group' do
      specify { is_expected.to eq 'Group information'}
    end

    context 'when group is a child group' do
      let(:group) { build(:group, parent: root_group) }

      specify { is_expected.to eq 'Subgroup information'}
    end
  end

  describe 'Menu Items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    shared_examples 'menu access rights' do
      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Activity' do
      let(:item_id) { :activity }

      specify { is_expected.not_to be_nil }

      it_behaves_like 'menu access rights'
    end

    describe 'Labels' do
      let(:item_id) { :labels }

      it_behaves_like 'menu access rights'
    end

    describe 'Members' do
      let(:item_id) { :members }

      it_behaves_like 'menu access rights'
    end
  end
end
