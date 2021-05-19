# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::HiddenMenu do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, current_ref: project.repository.root_ref) }

  describe '#render?' do
    subject { described_class.new(context) }

    context 'when menu does not have any menu items' do
      it 'returns false' do
        allow(subject).to receive(:has_renderable_items?).and_return(false)

        expect(subject.render?).to be false
      end
    end

    context 'when menu has menu items' do
      it 'returns true' do
        expect(subject.render?).to be true
      end
    end
  end

  describe 'Menu items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    shared_examples 'access rights checks' do
      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Activity' do
      let(:item_id) { :activity }

      context 'when user has access to the project' do
        specify { is_expected.not_to be_nil }

        describe 'when the user is not present' do
          let(:user) { nil }

          specify { is_expected.not_to be_nil }
        end
      end
    end

    describe 'Graph' do
      let(:item_id) { :graph }

      context 'when project repository is empty' do
        before do
          allow(project).to receive(:empty_repo?).and_return(true)
        end

        specify { is_expected.to be_nil }
      end

      it_behaves_like 'access rights checks'
    end

    describe 'New Issue' do
      let(:item_id) { :new_issue }

      it_behaves_like 'access rights checks'
    end

    describe 'Jobs' do
      let(:item_id) { :jobs }

      it_behaves_like 'access rights checks'
    end

    describe 'Commits' do
      let(:item_id) { :commits }

      context 'when project repository is empty' do
        before do
          allow(project).to receive(:empty_repo?).and_return(true)
        end

        specify { is_expected.to be_nil }
      end

      it_behaves_like 'access rights checks'
    end

    describe 'Issue Boards' do
      let(:item_id) { :issue_boards }

      it_behaves_like 'access rights checks'
    end
  end
end
