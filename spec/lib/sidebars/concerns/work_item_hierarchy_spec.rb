# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Concerns::WorkItemHierarchy do
  shared_examples 'hierarchy menu' do
    let(:item_id) { :hierarchy }
    specify { is_expected.not_to be_nil }
  end

  describe 'Project hierarchy menu item' do
    let_it_be_with_reload(:project) { create(:project, :repository) }

    let(:user) { project.owner }
    let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

    subject { Sidebars::Projects::Menus::ProjectInformationMenu.new(context).renderable_items.index { |e| e.item_id == item_id } }

    it_behaves_like 'hierarchy menu'
  end
end
