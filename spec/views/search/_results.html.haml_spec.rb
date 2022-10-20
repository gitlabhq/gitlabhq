# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'search/_results' do
  let(:user) { create(:user) }
  let(:search_objects) { Issue.page(1).per(2) }
  let(:scope) { 'issues' }
  let(:term) { 'foo' }

  before do
    controller.params[:action] = 'show'
    controller.params[:search] = term

    allow(self).to receive(:current_user).and_return(user)
    allow(@search_results).to receive(:formatted_count).with(scope).and_return(10)
    allow(self).to receive(:search_count_path).with(any_args).and_return("test count link")
    allow(self).to receive(:search_path).with(any_args).and_return("link test")

    stub_feature_flags(search_page_vertical_nav: false)

    create_list(:issue, 3)

    @search_objects = search_objects
    @scope = scope
    @search_term = term
    @search_service = SearchServicePresenter.new(SearchService.new(user, search: term, scope: scope))

    allow(@search_service).to receive(:search_objects).and_return(search_objects)
  end

  it 'displays the page size' do
    render

    expect(rendered).to have_content('Showing 1 - 2 of 3 issues for foo')
  end

  context 'when searching notes which contain quotes in markdown' do
    let_it_be(:project) { create(:project) }
    let_it_be(:issue) { create(:issue, project: project, title: '*') }
    let_it_be(:note) { create(:discussion_note_on_issue, noteable: issue, project: issue.project, note: '```"helloworld"```') }

    let(:scope) { 'notes' }
    let(:search_objects) { Note.page(1).per(2) }
    let(:term) { 'helloworld' }

    it 'renders plain quotes' do
      render

      expect(rendered).to include('"<mark>helloworld</mark>"')
    end
  end

  context 'when search results do not have a count' do
    before do
      @search_objects = @search_objects.without_count
    end

    it 'does not display the page size' do
      render

      expect(rendered).not_to have_content(/Showing .* of .*/)
    end
  end

  context 'rendering all types of search results' do
    let_it_be(:project) { create(:project, :repository, :wiki_repo) }
    let_it_be(:issue) { create(:issue, project: project, title: 'testing') }
    let_it_be(:merge_request) { create(:merge_request, title: 'testing', source_project: project, target_project: project) }
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

            expect(rendered).to have_selector('[data-track-action=click_text]')
            expect(rendered).to have_selector('[data-track-property=search_result]')
          end
        end

        context 'when admin mode is disabled' do
          it 'does not render the click text event tracking attributes' do
            render

            expect(rendered).not_to have_selector('[data-track-action=click_text]')
            expect(rendered).not_to have_selector('[data-track-property=search_result]')
          end
        end

        it 'does render the sidebar' do
          render

          expect(rendered).to have_selector('#js-search-sidebar')
        end
      end
    end

    describe 'git blame click tracking' do
      let(:scope) { 'blobs' }
      let(:search_objects) { Gitlab::ProjectSearchResults.new(user, 'testing', project: project).objects(scope) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'renders the click link event tracking attributes' do
          render

          expect(rendered).to have_selector('[data-track-action=click_link]')
          expect(rendered).to have_selector('[data-track-label=git_blame]')
          expect(rendered).to have_selector('[data-track-property=search_result]')
        end
      end

      context 'when admin mode is disabled' do
        it 'does not render the click link event tracking attributes' do
          render

          expect(rendered).not_to have_selector('[data-track-action=click_link]')
          expect(rendered).not_to have_selector('[data-track-label=git_blame]')
          expect(rendered).not_to have_selector('[data-track-property=search_result]')
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

            expect(rendered).to have_selector('[data-track-action=click_text]')
            expect(rendered).to have_selector('[data-track-property=search_result]')
          end
        end

        context 'when admin mode is disabled' do
          it 'does not render the click text event tracking attributes' do
            render

            expect(rendered).not_to have_selector('[data-track-action=click_text]')
            expect(rendered).not_to have_selector('[data-track-property=search_result]')
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
