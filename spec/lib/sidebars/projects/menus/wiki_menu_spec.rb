# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::WikiMenu, feature_category: :navigation do
  let(:project) { build(:project) }
  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  subject { described_class.new(context) }

  it 'does not contain any sub menu' do
    expect(subject.has_items?).to be false
  end

  describe '#render?' do
    context 'when user can access project wiki' do
      it 'returns true' do
        expect(subject.render?).to be true
      end

      context 'when user cannot access project wiki' do
        let(:user) { nil }

        it 'returns false' do
          expect(subject.render?).to be false
        end
      end
    end
  end

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:menu) { subject }
    let(:extra_attrs) do
      {
        super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::PlanMenu,
        item_id: :project_wiki
      }
    end
  end
end
