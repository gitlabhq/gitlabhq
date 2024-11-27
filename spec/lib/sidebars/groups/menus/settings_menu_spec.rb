# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::SettingsMenu, :with_license, feature_category: :navigation do
  let_it_be(:owner) { create(:user) }

  let_it_be_with_refind(:group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  let(:menu) { described_class.new(context) }

  describe '#render?' do
    context 'when user cannot admin group' do
      let(:user) { nil }

      it 'returns false' do
        expect(menu.render?).to be false
      end
    end
  end

  describe '#separated?' do
    it 'returns true' do
      expect(menu.separated?).to be true
    end
  end

  describe 'Menu items' do
    subject { menu.renderable_items.find { |e| e.item_id == item_id } }

    shared_examples 'access rights checks' do
      it { is_expected.not_to be_nil }

      context 'when the user does not have access' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end

    describe 'General menu' do
      let(:item_id) { :general }

      it_behaves_like 'access rights checks'
    end

    describe 'Integrations menu' do
      let(:item_id) { :integrations }

      it_behaves_like 'access rights checks'
    end

    describe 'Projects menu' do
      let(:item_id) { :group_projects }

      it_behaves_like 'access rights checks'
    end

    describe 'Access tokens' do
      let(:item_id) { :access_tokens }

      it_behaves_like 'access rights checks'
    end

    describe 'Repository menu' do
      let(:item_id) { :repository }

      it_behaves_like 'access rights checks'
    end

    describe 'CI/CD menu' do
      let(:item_id) { :ci_cd }

      it_behaves_like 'access rights checks'
    end

    describe 'Applications menu' do
      let(:item_id) { :applications }

      it_behaves_like 'access rights checks'
    end

    describe 'Packages and registries' do
      let(:item_id) { :packages_and_registries }

      before do
        allow(group).to receive(:packages_feature_enabled?).and_return(packages_enabled)
      end

      describe 'when packages feature is disabled' do
        let(:packages_enabled) { false }

        it { is_expected.to be_nil }
      end

      describe 'when packages feature is enabled' do
        let(:packages_enabled) { true }

        it_behaves_like 'access rights checks'
      end
    end
  end
end
