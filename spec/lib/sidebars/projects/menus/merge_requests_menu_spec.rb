# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::MergeRequestsMenu, feature_category: :navigation do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  subject { described_class.new(context) }

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:menu) { subject }
    let(:extra_attrs) do
      {
        item_id: :project_merge_request_list,
        pill_count: menu.pill_count,
        pill_count_field: menu.pill_count_field,
        has_pill: menu.has_pill?,
        super_sidebar_parent: Sidebars::Projects::SuperSidebarMenus::CodeMenu
      }
    end
  end

  describe '#render?' do
    context 'when repository is not present' do
      let(:project) { build(:project) }

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end

    context 'when repository is present' do
      context 'when user can read merge requests' do
        it 'returns true' do
          expect(subject.render?).to eq true
        end
      end

      context 'when user cannot read merge requests' do
        let(:user) { nil }

        it 'returns false' do
          expect(subject.render?).to eq false
        end
      end
    end
  end

  describe '#pill_count_field' do
    it 'returns the correct GraphQL field name' do
      expect(subject.pill_count_field).to eq('openMergeRequestsCount')
    end
  end
end
