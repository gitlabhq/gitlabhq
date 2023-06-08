# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::ConfluenceMenu, feature_category: :navigation do
  let_it_be_with_refind(:project) { create(:project, has_external_wiki: true) }

  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  subject { described_class.new(context) }

  describe 'render?' do
    context 'when Confluence integration is not present' do
      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end

    context 'when Confluence integration is present' do
      let!(:confluence) { create(:confluence_integration, project: project, active: active) }

      context 'when integration is disabled' do
        let(:active) { false }

        it 'returns false' do
          expect(subject.render?).to eq false
        end
      end

      context 'when issues integration is enabled' do
        let(:active) { true }

        it 'returns true' do
          expect(subject.render?).to eq true
        end

        it 'does not contain any sub menu' do
          expect(subject.has_items?).to be false
        end
      end
    end
  end

  describe 'serialize_as_menu_item_args' do
    it 'renders as part of the Plan section' do
      expect(subject.serialize_as_menu_item_args).to include({
        item_id: :confluence,
        super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::PlanMenu
      })
    end
  end
end
