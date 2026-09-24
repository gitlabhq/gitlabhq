# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'search/_results', :with_current_organization, feature_category: :global_search do
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
    let_it_be(:project, freeze: false) { create(:project) }
    let_it_be(:issue, freeze: false) { create(:issue, project: project, title: '*') }
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
    let_it_be(:project, freeze: false) { create(:project, :repository, :wiki_repo) }
    let_it_be(:label, freeze: false) { create(:label, project: project, title: 'test label') }
    let_it_be(:issue, freeze: false) { create(:issue, project: project, title: 'testing', labels: [label]) }
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
          context 'when no search request ID was minted' do
            it 'renders the click text event tracking attributes' do
              render

              expect(rendered)
                .to trigger_internal_events('click_search_result').on_click
                .with(additional_properties: { label: scope, value: 1 })
            end
          end

          context 'when a search request ID was minted' do
            let(:search_request_id) { '11111111-2222-3333-4444-555555555555' }

            before do
              assign(:search_request_id, search_request_id)
            end

            it 'renders the click text event tracking attributes with the join key' do
              render

              expect(rendered)
                .to trigger_internal_events('click_search_result').on_click
                .with(additional_properties: { label: scope, value: 1, property: search_request_id })
            end

            # The matcher above asserts each data attribute independently against the whole
            # document, so it cannot prove they land together. This does.
            it 'puts the join key on every tracked result link' do
              render

              properties = tracked_link_properties(rendered)

              expect(properties.size).to eq(search_objects.size)
              expect(properties).to all(eq(search_request_id))
            end
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
          context 'when no search request ID was minted' do
            it 'renders the click text event tracking attributes' do
              render

              expect(rendered)
                .to trigger_internal_events('click_search_result').on_click
                .with(additional_properties: { label: scope, value: 1 })
            end
          end

          context 'when a search request ID was minted' do
            let(:search_request_id) { '11111111-2222-3333-4444-555555555555' }

            before do
              assign(:search_request_id, search_request_id)
            end

            it 'renders the click text event tracking attributes with the join key' do
              render

              expect(rendered)
                .to trigger_internal_events('click_search_result').on_click
                .with(additional_properties: { label: scope, value: 1, property: search_request_id })
            end

            it 'puts the join key on every tracked result link' do
              render

              properties = tracked_link_properties(rendered)

              expect(properties.size).to eq(search_objects.size)
              expect(properties).to all(eq(search_request_id))
            end
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

    # _commit.html.haml is the only call site that hands the hash across a partial
    # boundary (link_data_attrs -> projects/commits/_commit), and _results_list renders
    # commits through its own branch, so no other scope covers this path.
    context 'when scope is commits' do
      let(:scope) { 'commits' }
      # Unlike the other scopes, 'testing' matches a single commit in the gitlab-test
      # fixture, and a count of 1 cannot distinguish "every row" from "the first row".
      # 'merge' matches 11, so the per-row assertions below are load-bearing here.
      let(:search_objects) { Gitlab::ProjectSearchResults.new(user, 'merge', project: project).objects(scope) }

      context 'when admin mode is enabled', :enable_admin_mode do
        context 'when no search request ID was minted' do
          it 'renders no join key on the commit link' do
            render

            expect(rendered).to have_css("[data-event-tracking='click_search_result']")
            expect(rendered).not_to have_css('[data-event-property]')
          end
        end

        context 'when a search request ID was minted' do
          let(:search_request_id) { '11111111-2222-3333-4444-555555555555' }

          before do
            assign(:search_request_id, search_request_id)
          end

          it 'carries the join key through link_data_attrs onto the commit link' do
            render

            properties = tracked_link_properties(rendered)

            # Guards the fixture itself: at one commit the assertions below cannot tell
            # "every row" from "the first row".
            expect(search_objects.size).to be > 1
            expect(properties.size).to eq(search_objects.size)
            expect(properties).to all(eq(search_request_id))
          end
        end
      end
    end
  end

  # _user is the only result partial rendered from the %table branch of
  # _results_list (:26-34) via render_if_exists, so no other scope covers it.
  context 'when scope is users' do
    let_it_be(:matching_users) { create_list(:user, 2, name: 'testing person') }

    let(:scope) { 'users' }
    let(:term) { 'testing' }
    # Mirrors SearchServicePresenter#search_objects, which eager loads :status for this
    # scope; user_status raises in test if the association is not preloaded.
    let(:search_objects) { User.id_in(matching_users.map(&:id)).eager_load(:status).page(1) }

    context 'when no search request ID was minted' do
      it 'renders no join key on the user links' do
        render

        expect(rendered).to have_css("[data-event-tracking='click_search_result']")
        expect(rendered).not_to have_css('[data-event-property]')
      end
    end

    context 'when a search request ID was minted' do
      let(:search_request_id) { '11111111-2222-3333-4444-555555555555' }

      before do
        assign(:search_request_id, search_request_id)
      end

      it 'puts the join key on every tracked user link' do
        render

        properties = tracked_link_properties(rendered)

        expect(search_objects.size).to be > 1
        expect(properties.size).to eq(search_objects.size)
        expect(properties).to all(eq(search_request_id))
      end
    end
  end

  context 'when scope is milestones and a result is a group milestone' do
    let_it_be(:group, freeze: false) { create(:group) }
    let_it_be(:group_milestone, freeze: false) { create(:milestone, group: group, title: 'testing') }

    let(:scope) { 'milestones' }
    let(:term) { 'testing' }
    let(:search_objects) { Milestone.id_in(group_milestone.id).page(1) }

    it 'links to the group milestone and shows the group name' do
      render

      expect(rendered).to have_link(href: group_milestone_path(group, group_milestone))
      expect(rendered).to have_content(group.full_name)
    end
  end

  context 'when scope is snippet_titles' do
    let_it_be(:snippets) { create_list(:personal_snippet, 2, :public, title: 'testing snippet') }

    let(:scope) { 'snippet_titles' }
    let(:term) { 'testing' }
    let(:search_objects) { Snippet.id_in(snippets.map(&:id)).page(1) }

    context 'when no search request ID was minted' do
      it 'renders no join key on the snippet links' do
        render

        expect(rendered).to have_css("[data-event-tracking='click_search_result']")
        expect(rendered).not_to have_css('[data-event-property]')
      end
    end

    context 'when a search request ID was minted' do
      let(:search_request_id) { '11111111-2222-3333-4444-555555555555' }

      before do
        assign(:search_request_id, search_request_id)
      end

      it 'puts the join key on every tracked snippet link' do
        render

        properties = tracked_link_properties(rendered)

        expect(search_objects.size).to be > 1
        expect(properties.size).to eq(search_objects.size)
        expect(properties).to all(eq(search_request_id))
      end
    end
  end

  # _results_list falls through to render_if_exists "search/results/work_item" for this
  # scope, and under EE that partial's else branch render_ce's back to the CE one, so this
  # is the only view-spec cover for app/views/search/results/_work_item.html.haml.
  context 'when scope is work_items' do
    let_it_be(:work_items) { create_list(:work_item, 2, title: 'testing work item') }

    let(:scope) { 'work_items' }
    let(:term) { 'testing' }
    let(:search_objects) { WorkItem.id_in(work_items.map(&:id)).page(1) }

    context 'when no search request ID was minted' do
      it 'renders no join key on the work item links' do
        render

        expect(rendered).to have_css("[data-event-tracking='click_search_result']")
        expect(rendered).not_to have_css('[data-event-property]')
      end
    end

    context 'when a search request ID was minted' do
      let(:search_request_id) { '11111111-2222-3333-4444-555555555555' }

      before do
        assign(:search_request_id, search_request_id)
      end

      it 'puts the join key on every tracked work item link' do
        render

        properties = tracked_link_properties(rendered)

        expect(search_objects.size).to be > 1
        expect(properties.size).to eq(search_objects.size)
        expect(properties).to all(eq(search_request_id))
      end
    end
  end

  context 'when searching groups' do
    let_it_be(:group) { create(:group, name: 'foo-group') }

    let(:scope) { 'groups' }
    let(:search_objects) { Group.page(1).per(2) }

    it 'renders the group list' do
      render

      expect(rendered).to have_link(group.full_name, href: group_path(group))
    end
  end
end
