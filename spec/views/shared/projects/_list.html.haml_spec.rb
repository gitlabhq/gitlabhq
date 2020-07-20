# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/projects/_list' do
  let(:group) { create(:group) }

  before do
    allow(view).to receive(:projects).and_return(projects)
    allow(view).to receive(:project_list_cache_key).and_return('fake_cache_key')
  end

  context 'with projects' do
    let(:projects) { build_stubbed_list(:project, 1) }

    it 'renders the list of projects' do
      render

      projects.each do |project|
        expect(rendered).to have_content(project.name)
      end
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

          expect(rendered).to have_content(s_('UserProfile|Explore public groups to find projects to contribute to.'))
        end
      end

      context 'for a non-explore page' do
        it 'renders a no-content message' do
          render

          expect(rendered).to have_content(s_('UserProfile|This user doesn\'t have any personal projects'))
        end
      end
    end
  end
end
