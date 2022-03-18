# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::SettingsMenu do
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

  describe 'Menu items' do
    subject { menu.renderable_items.find { |e| e.item_id == item_id } }

    shared_examples 'access rights checks' do
      specify { is_expected.not_to be_nil }

      context 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
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

    describe 'Access Tokens' do
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

      describe 'when runner list group view is disabled' do
        before do
          stub_feature_flags(runner_list_group_view_vue_ui: false)
        end

        it_behaves_like 'access rights checks'

        it 'has group runners as active_routes' do
          expect(subject.active_routes[:path]).to match_array %w[ci_cd#show groups/runners#show groups/runners#edit]
        end
      end
    end

    describe 'Applications menu' do
      let(:item_id) { :applications }

      it_behaves_like 'access rights checks'
    end

    describe 'Packages & Registries' do
      let(:item_id) { :packages_and_registries }

      before do
        allow(group).to receive(:packages_feature_enabled?).and_return(packages_enabled)
      end

      describe 'when packages feature is disabled' do
        let(:packages_enabled) { false }

        specify { is_expected.to be_nil }
      end

      describe 'when packages feature is enabled' do
        let(:packages_enabled) { true }

        it_behaves_like 'access rights checks'
      end
    end
  end
end
