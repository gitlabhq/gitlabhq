# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'search/_results', feature_category: :global_search do
  let_it_be(:user) { create(:user) }

  let(:search_objects) { Issue.page(1).per(2) }
  let(:scope) { 'issues' }
  let(:term) { 'foo' }
  let(:search_results) { instance_double('Gitlab::SearchResults', { formatted_count: 10, current_user: user }) }

  before do
    controller.params[:action] = 'show'
    controller.params[:search] = term

    create_list(:issue, 3)

    allow(view).to receive(:current_user) { user }

    assign(:search_count_path, 'test count link')
    assign(:search_path, 'link test')
    assign(:search_results, search_results)
    assign(:search_objects, search_objects)
    assign(:search_term, term)
    assign(:scope, scope)

    search_service_presenter = SearchServicePresenter.new(SearchService.new(user, search: term, scope: scope))
    allow(search_service_presenter).to receive(:search_objects).and_return(search_objects)
    assign(:search_service_presenter, search_service_presenter)
  end

  context 'for page size' do
    context 'when search results have a count' do
      it 'displays the page size' do
        render

        expect(rendered).to have_content('Showing 1 - 2 of 3 issues for foo')
      end
    end

    context 'when search results do not have a count' do
      let(:search_objects) { Issue.page(1).per(2).without_count }

      it 'does not display the page size' do
        render

        expect(rendered).not_to have_content(/Showing .* of .*/)
      end
    end
  end

  context 'when searching notes which contain quotes in markdown' do
    let_it_be(:project) { create(:project) }
    let_it_be(:issue) { create(:issue, project: project, title: '*') }
    let_it_be(:note) do
      create(:discussion_note_on_issue, noteable: issue, project: issue.project, note: '```"helloworld"```')
    end

    let(:scope) { 'notes' }
    let(:search_objects) { Note.page(1).per(2) }
    let(:term) { 'helloworld' }

    it 'renders plain quotes' do
      render

      expect(rendered).to include('"<mark>helloworld</mark>"')
    end
  end

  context 'for rendering all types of search results' do
    let_it_be(:project) { create(:project, :repository, :wiki_repo) }
    let_it_be(:label) { create(:label, project: project, title: 'test label') }
    let_it_be(:issue) { create(:issue, project: project, title: 'testing', labels: [label]) }
    let_it_be(:merge_request) do
      create(:merge_request, title: 'testing', source_project: project, target_project: project)
    end

    let_it_be(:milestone) { create(:milestone, title: 'testing', project: project) }
    let_it_be(:note) { create(:discussion_note_on_issue, project: project, note: 'testing') }
    let_it_be(:wiki_blob) { create(:wiki_page, wiki: project.wiki, content: 'testing') }
    let_it_be(:user) { create(:admin) }

    %w[issues merge_requests].each do |search_scope|
      context "when scope is #{search_scope}" do
        let(:scope) { search_scope }
        let(:search_objects) { Gitlab::ProjectSearchResults.new(user, 'testing', project: project).objects(scope) }

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'renders the click text event tracking attributes' do
            render

            expect(rendered)
              .to trigger_internal_events('click_search_result').on_click
              .with(additional_properties: { label: scope, value: 1 })
          end
        end

        context 'when admin mode is disabled' do
          it 'does not render the click text event tracking attributes' do
            render

            expect(rendered).not_to trigger_internal_events
          end
        end
      end
    end

    context 'for git blame click tracking' do
      let(:scope) { 'blobs' }
      let(:search_objects) { Gitlab::ProjectSearchResults.new(user, 'testing', project: project).objects(scope) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'renders the click link event tracking attributes' do
          render

          expect(rendered).to have_tracking(action: 'click_link', label: 'git_blame', property: 'search_result')
        end
      end

      context 'when admin mode is disabled' do
        it 'does not render the click link event tracking attributes' do
          render

          expect(rendered).not_to have_tracking(action: 'click_link', label: 'git_blame', property: 'search_result')
        end
      end
    end

    %w[blobs notes wiki_blobs milestones].each do |search_scope|
      context "when scope is #{search_scope}" do
        let(:scope) { search_scope }
        let(:search_objects) { Gitlab::ProjectSearchResults.new(user, 'testing', project: project).objects(scope) }

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'renders the click text event tracking attributes' do
            render

            expect(rendered)
              .to trigger_internal_events('click_search_result').on_click
              .with(additional_properties: { label: scope, value: 1 })
          end
        end

        context 'when admin mode is disabled' do
          it 'does not render the click text event tracking attributes' do
            render

            expect(rendered).not_to trigger_internal_events
          end
        end

        it 'does not render the sidebar' do
          render

          expect(rendered).not_to have_selector('form.search-sidebar')
        end
      end
    end
  end
end
