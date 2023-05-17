# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::SnippetsMenu, feature_category: :navigation do
  let(:project) { build(:project) }
  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  subject { described_class.new(context) }

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:menu) { subject }
    let(:extra_attrs) do
      {
        super_sidebar_parent: ::Sidebars::Projects::SuperSidebarMenus::CodeMenu,
        item_id: :project_snippets
      }
    end
  end

  describe '#render?' do
    context 'when user cannot access snippets' do
      let(:user) { nil }

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end

    context 'when user can access snippets' do
      it 'returns true' do
        expect(subject.render?).to eq true
      end
    end
  end
end
