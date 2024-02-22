# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/projects/_list' do
  let(:group) { create(:group) }

  before do
    allow(view).to receive(:projects).and_return(projects)
  end

  context 'with projects' do
    let(:projects) { build_stubbed_list(:project, 1) }

    it 'renders the list of projects' do
      render

      projects.each do |project|
        expect(rendered).to have_content(project.name)
      end
    end

    it "will not show elements a user shouldn't be able to see" do
      allow(view).to receive(:can_show_last_commit_in_list?).and_return(false)
      allow(view).to receive(:able_to_see_merge_requests?).and_return(false)
      allow(view).to receive(:able_to_see_issues?).and_return(false)

      render

      expect(rendered).not_to have_css('a.commit-row-message')
      expect(rendered).not_to have_css('a.issues')
      expect(rendered).not_to have_css('a.merge-requests')
    end

    it 'renders list in list view' do
      expect(rendered).not_to have_css('.gl-new-card')
    end
  end

  context 'with projects in card mode' do
    let(:projects) { build_stubbed_list(:project, 1) }

    it 'renders card mode when set to true' do
      render template: 'shared/projects/_list', locals: { card_mode: true }

      expect(rendered).to have_css('.gl-new-card')
    end
  end

  context 'without projects' do
    let(:projects) { [] }

    context 'when @contributed_projects is set' do
      context 'and is empty' do
        before do
          @contributed_projects = []
        end

        it 'renders a no-content message' do
          render

          expect(rendered).to have_content(s_('UserProfile|This user hasn\'t contributed to any projects'))
        end
      end
    end

    context 'when @starred_projects is set' do
      context 'and is empty' do
        before do
          @starred_projects = []
        end

        it 'renders a no-content message' do
          render

          expect(rendered).to have_content(s_('UserProfile|This user hasn\'t starred any projects'))
        end
      end
    end

    context 'and without a special instance variable' do
      context 'for an explore_page' do
        before do
          allow(view).to receive(:explore_page).and_return(true)
        end

        it 'renders a no-content message' do
          render

          expect(rendered).to have_content(s_('UserProfile|Explore public groups to find projects to contribute to'))
        end
      end

      context 'for a non-explore page' do
        it 'renders a no-content message' do
          render

          expect(rendered).to have_content(s_('UserProfile|There are no projects available to be displayed here'))
        end
      end
    end
  end
end
