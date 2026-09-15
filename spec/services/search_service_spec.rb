# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchService, :with_current_organization, feature_category: :global_search do
  let_it_be(:user) { create(:user) }

  let_it_be(:accessible_group) { create(:group, :private) }
  let_it_be(:inaccessible_group) { create(:group, :private) }
  let_it_be(:group_member) { create(:group_member, group: accessible_group, user: user) }

  let_it_be(:accessible_project) do
    create(:project, :private, name: 'accessible_project', maintainers: user)
  end

  let_it_be(:note) { create(:note_on_issue, project: accessible_project) }

  let_it_be(:inaccessible_project) { create(:project, :private, name: 'inaccessible_project') }

  let_it_be(:snippet) { create(:personal_snippet, author: user) }
  let_it_be(:group_project) { create(:project, group: accessible_group, name: 'group_project') }
  let_it_be(:public_project) { create(:project, :public, name: 'public_project') }

  let(:page) { 1 }
  let(:per_page) { described_class::DEFAULT_PER_PAGE }
  let(:valid_search) { "what is love?" }

  subject(:search_service) { described_class.new(user, search: search, scope: scope, page: page, per_page: per_page) }

  describe '#project' do
    context 'when the project is accessible' do
      it 'returns the project' do
        project = described_class.new(user, project_id: accessible_project.id, search: valid_search).project

        expect(project).to eq accessible_project
      end

      it 'returns the project for guests' do
        search_project = create :project
        search_project.add_guest(user)

        project = described_class.new(user, project_id: search_project.id, search: valid_search).project

        expect(project).to eq search_project
      end
    end

    context 'when the project is not accessible' do
      it 'returns nil' do
        project = described_class.new(user, project_id: inaccessible_project.id, search: valid_search).project

        expect(project).to be_nil
      end
    end

    context 'when there is no project_id' do
      it 'returns nil' do
        project = described_class.new(user, search: valid_search).project

        expect(project).to be_nil
      end
    end
  end

  describe '#group' do
    context 'when the group is accessible' do
      it 'returns the group' do
        group = described_class.new(user, group_id: accessible_group.id, search: valid_search).group

        expect(group).to eq accessible_group
      end
    end

    context 'when the group is not accessible' do
      it 'returns nil' do
        group = described_class.new(user, group_id: inaccessible_group.id, search: valid_search).group

        expect(group).to be_nil
      end
    end

    context 'when there is no group_id' do
      it 'returns nil' do
        group = described_class.new(user, search: valid_search).group

        expect(group).to be_nil
      end
    end
  end

  describe '#search_type' do
    subject { described_class.new(user, search: valid_search).search_type }

    it { is_expected.to eq('basic') }
  end

  describe '#user_requested_scope' do
    it 'returns the scope param as provided by the user' do
      service = described_class.new(user, scope: 'blobs', search: valid_search)

      expect(service.user_requested_scope).to eq('blobs')
    end

    it 'returns nil when no scope param is provided' do
      service = described_class.new(user, search: valid_search)

      expect(service.user_requested_scope).to be_nil
    end
  end

  describe '#show_snippets?' do
    context 'when :snippets is \'true\'' do
      it 'returns true' do
        show_snippets = described_class.new(user, snippets: 'true').show_snippets?

        expect(show_snippets).to be_truthy
      end
    end

    context 'when :snippets is not \'true\'' do
      it 'returns false' do
        show_snippets = described_class.new(user, snippets: 'tru').show_snippets?

        expect(show_snippets).to be_falsey
      end
    end

    context 'when :snippets is missing' do
      it 'returns false' do
        show_snippets = described_class.new(user).show_snippets?

        expect(show_snippets).to be_falsey
      end
    end
  end

  describe '#scope' do
    context 'with accessible project_id' do
      context 'and allowed scope' do
        it 'returns the specified scope' do
          scope = described_class.new(user, project_id: accessible_project.id,
            scope: 'notes', search: valid_search).scope

          expect(scope).to eq 'notes'
        end
      end

      context 'and disallowed scope' do
        it 'returns the default scope' do
          scope = described_class.new(user, project_id: accessible_project.id,
            scope: 'projects', search: valid_search).scope

          expect(scope).to eq 'blobs'
        end
      end

      context 'and no scope' do
        it 'returns the default scope' do
          scope = described_class.new(user, project_id: accessible_project.id, search: valid_search).scope

          expect(scope).to eq 'blobs'
        end
      end
    end

    context 'with \'true\' snippets' do
      context 'and allowed scope' do
        it 'returns the specified scope' do
          scope = described_class.new(user, snippets: 'true', scope: 'snippet_titles').scope

          expect(scope).to eq 'snippet_titles'
        end
      end

      context 'and disallowed scope' do
        it 'returns the default scope' do
          scope = described_class.new(user, snippets: 'true', scope: 'projects').scope

          expect(scope).to eq 'snippet_titles'
        end
      end

      context 'and no scope' do
        it 'returns the default scope' do
          scope = described_class.new(user, snippets: 'true').scope

          expect(scope).to eq 'snippet_titles'
        end
      end
    end

    context 'with no project_id, no snippets' do
      context 'and allowed scope' do
        it 'returns the specified scope' do
          scope = described_class.new(user, scope: 'work_items').scope

          expect(scope).to eq 'work_items'
        end
      end

      context 'and disallowed scope' do
        it 'returns the default scope' do
          scope = described_class.new(user, scope: 'blobs').scope

          expect(scope).to eq 'projects'
        end
      end

      context 'and no scope' do
        it 'returns the default scope' do
          scope = described_class.new(user).scope

          expect(scope).to eq 'projects'
        end
      end
    end
  end

  describe '#search_results' do
    context 'with accessible project_id' do
      it 'returns an instance of Gitlab::ProjectSearchResults' do
        search_results = described_class.new(
          user,
          project_id: accessible_project.id,
          scope: 'notes',
          search: note.note).search_results

        expect(search_results).to be_a Gitlab::ProjectSearchResults
      end
    end

    context 'with accessible project_id and \'true\' snippets' do
      it 'returns an instance of Gitlab::ProjectSearchResults' do
        search_results = described_class.new(
          user,
          project_id: accessible_project.id,
          snippets: 'true',
          scope: 'notes',
          search: note.note).search_results

        expect(search_results).to be_a Gitlab::ProjectSearchResults
      end
    end

    context 'with \'true\' snippets' do
      it 'returns an instance of Gitlab::SnippetSearchResults' do
        search_results = described_class.new(
          user,
          snippets: 'true',
          search: snippet.title).search_results

        expect(search_results).to be_a Gitlab::SnippetSearchResults
      end
    end

    context 'with no project_id and no snippets' do
      it 'returns an instance of Gitlab::SearchResults' do
        search_results = described_class.new(
          user,
          search: public_project.name).search_results

        expect(search_results).to be_a Gitlab::SearchResults
      end
    end
  end

  describe '#search_objects' do
    let(:search) { '' }
    let(:scope) { nil }

    describe 'per_page: parameter' do
      context 'when nil' do
        let(:per_page) { nil }

        it "defaults to #{described_class::DEFAULT_PER_PAGE}" do
          expect_next_instance_of(Gitlab::SearchResults) do |search_results|
            expect(search_results).to receive(:objects)
            .with(anything, hash_including(per_page: described_class::DEFAULT_PER_PAGE))
            .and_call_original
          end

          search_service.search_objects
        end
      end

      context 'when empty string' do
        let(:per_page) { '' }

        it "defaults to #{described_class::DEFAULT_PER_PAGE}" do
          expect_next_instance_of(Gitlab::SearchResults) do |search_results|
            expect(search_results).to receive(:objects)
            .with(anything, hash_including(per_page: described_class::DEFAULT_PER_PAGE))
            .and_call_original
          end

          search_service.search_objects
        end
      end

      context 'when negative' do
        let(:per_page) { '-1' }

        it "defaults to #{described_class::DEFAULT_PER_PAGE}" do
          expect_next_instance_of(Gitlab::SearchResults) do |search_results|
            expect(search_results).to receive(:objects)
              .with(anything, hash_including(per_page: described_class::DEFAULT_PER_PAGE))
              .and_call_original
          end

          search_service.search_objects
        end
      end

      context 'when present' do
        let(:per_page) { '50' }

        it "converts to integer and passes to search results" do
          expect_next_instance_of(Gitlab::SearchResults) do |search_results|
            expect(search_results).to receive(:objects)
              .with(anything, hash_including(per_page: 50))
              .and_call_original
          end

          search_service.search_objects
        end
      end

      context "when greater than #{described_class::MAX_PER_PAGE}" do
        let(:per_page) { described_class::MAX_PER_PAGE + 1 }

        it "passes #{described_class::MAX_PER_PAGE}" do
          expect_next_instance_of(Gitlab::SearchResults) do |search_results|
            expect(search_results).to receive(:objects)
              .with(anything, hash_including(per_page: described_class::MAX_PER_PAGE))
              .and_call_original
          end

          search_service.search_objects
        end
      end
    end

    describe 'page: parameter' do
      context 'when < 1' do
        let(:page) { 0 }

        it 'defaults to 1' do
          expect_next_instance_of(Gitlab::SearchResults) do |search_results|
            expect(search_results).to receive(:objects)
              .with(anything, hash_including(page: 1))
              .and_call_original
          end

          search_service.search_objects
        end
      end

      context 'when nil' do
        let(:page) { nil }

        it 'defaults to 1' do
          expect_next_instance_of(Gitlab::SearchResults) do |search_results|
            expect(search_results).to receive(:objects)
              .with(anything, hash_including(page: 1))
              .and_call_original
          end

          search_service.search_objects
        end
      end

      describe 'result window boundary' do
        using RSpec::Parameterized::TableSyntax

        let(:page) { requested_page }

        def objects_passed_to_search_results
          passed = nil

          expect_next_instance_of(Gitlab::SearchResults) do |search_results|
            expect(search_results).to receive(:objects) do |_scope, **kwargs|
              passed = kwargs
              Kaminari.paginate_array([]).page(kwargs[:page]).per(kwargs[:per_page])
            end
          end

          search_service.search_objects

          passed
        end

        # Elasticsearch answers `from + size > index.max_result_window` with an
        # HTTP 400, and advanced search derives `from` as `per_page * (page - 1)`
        # (ee/lib/search/elastic/formats.rb). So the deepest page advanced search
        # can reach is `MAX_RESULT_WINDOW / per_page`.
        context 'with advanced search' do
          before do
            allow(search_service).to receive(:search_type).and_return('advanced')
          end

          context 'when the requested page fits in the result window' do
            where(:per_page, :requested_page) do
              [
                [SearchService::DEFAULT_PER_PAGE, 1],
                [SearchService::DEFAULT_PER_PAGE, 500],
                [SearchService::MAX_PER_PAGE, 50],
                [3, 3333],
                [199, 50],
                [1, SearchService::MAX_RESULT_WINDOW]
              ]
            end

            with_them do
              it 'queries the requested page' do
                passed = objects_passed_to_search_results

                expect(passed[:page]).to eq(requested_page)
                expect(passed[:per_page]).to eq(per_page)

                from = passed[:per_page] * (passed[:page] - 1)
                expect(from + passed[:per_page]).to be <= described_class::MAX_RESULT_WINDOW
              end
            end
          end

          context 'when the requested page is past the result window' do
            where(:per_page, :requested_page) do
              [
                [SearchService::DEFAULT_PER_PAGE, 501],
                [SearchService::DEFAULT_PER_PAGE, 1000],
                [SearchService::MAX_PER_PAGE, 51],
                [3, 3334],
                [199, 51],
                [1, SearchService::MAX_RESULT_WINDOW + 1]
              ]
            end

            with_them do
              it 'returns an empty page at the requested offset without querying Elasticsearch' do
                expect(Gitlab::SearchResults).not_to receive(:new)

                objects = search_service.search_objects

                expect(objects.to_a).to be_empty
                # The headers describe what was served: the requested page, and no next page,
                # so a client walking `rel="next"` terminates here.
                expect(objects.current_page).to eq(requested_page)
                expect(objects.limit_value).to eq(per_page)
                expect(objects.offset_value).to eq(per_page * (requested_page - 1))
                expect(objects.next_page).to be_nil
                # Kaminari reports no neighbours at all for a page past the
                # fabricated total, so there is no `prev` link either and a client
                # pages back via `rel="first"`. The one exception is a per_page
                # that does not divide MAX_RESULT_WINDOW, where the first
                # unreachable page *is* the fabricated last page and `prev`
                # points at the deepest page that can still be served.
                last_fabricated_page = (described_class::MAX_RESULT_WINDOW.to_f / per_page).ceil
                expected_prev = requested_page > last_fabricated_page ? nil : requested_page - 1
                expect(objects.prev_page).to eq(expected_prev)
                # The fabricated total sits at MAX_COUNT_LIMIT so OffsetPagination
                # omits X-Total rather than publishing it. See
                # SearchService#results_beyond_result_window.
                expect(objects.total_count).to eq(described_class::MAX_RESULT_WINDOW)
                expect(objects.total_pages).to eq((described_class::MAX_RESULT_WINDOW.to_f / per_page).ceil)
              end
            end
          end
        end

        # Basic search pages with a SQL OFFSET and Zoekt with its own pagination:
        # neither has a result window, so neither is capped.
        context 'with a search type that has no result window' do
          where(:search_type, :per_page, :requested_page) do
            [
              ['basic', SearchService::DEFAULT_PER_PAGE, 501],
              ['basic', SearchService::DEFAULT_PER_PAGE, 1000],
              ['basic', SearchService::MAX_PER_PAGE, 51],
              ['zoekt', SearchService::DEFAULT_PER_PAGE, 1000]
            ]
          end

          with_them do
            before do
              allow(search_service).to receive(:search_type).and_return(search_type)
            end

            it 'queries the requested page' do
              passed = objects_passed_to_search_results

              expect(passed[:page]).to eq(requested_page)
              expect(passed[:per_page]).to eq(per_page)
            end
          end
        end

        context 'when the search type is not stubbed' do
          let(:per_page) { described_class::DEFAULT_PER_PAGE }
          let(:requested_page) { 1000 }

          it 'resolves to basic search and queries the requested page' do
            expect(search_service.search_type).to eq('basic')

            passed = objects_passed_to_search_results

            expect(passed[:page]).to eq(1000)
          end
        end
      end
    end

    context 'with accessible project_id' do
      it 'returns objects in the project' do
        search_objects = described_class.new(
          user,
          project_id: accessible_project.id,
          scope: 'notes',
          search: note.note).search_objects

        expect(search_objects.first).to eq note
      end
    end

    context 'with accessible project_id and \'true\' snippets' do
      it 'returns objects in the project' do
        search_objects = described_class.new(
          user,
          project_id: accessible_project.id,
          snippets: 'true',
          scope: 'notes',
          search: note.note).search_objects

        expect(search_objects.first).to eq note
      end
    end

    context 'with \'true\' snippets' do
      it 'returns objects in snippets' do
        search_objects = described_class.new(
          user,
          snippets: 'true',
          search: snippet.title,
          organization_id: current_organization.id).search_objects

        expect(search_objects.first).to eq snippet
      end
    end

    context 'with accessible group_id' do
      it 'returns objects in the group' do
        search_objects = described_class.new(
          user,
          group_id: accessible_group.id,
          search: group_project.name).search_objects

        expect(search_objects.first).to eq group_project
      end
    end

    context 'with no project_id, group_id or snippets' do
      it 'returns objects in global' do
        search_objects = described_class.new(
          user,
          search: public_project.name).search_objects

        expect(search_objects.first).to eq public_project
      end
    end

    it_behaves_like 'a redacted search results'
  end

  describe '#abuse_messages' do
    let(:scope) { 'work_items' }
    let(:search) { 'foobar' }
    let(:params) { instance_double(Search::Params) }

    before do
      allow(Search::Params).to receive(:new).and_return(params)
    end

    it 'returns an empty array when not abusive' do
      allow(search_service).to receive(:abuse_detected?).and_return false
      expect(search_service.abuse_messages).to be_empty
    end

    it 'calls on abuse_detection.errors.full_messages when abusive' do
      allow(search_service).to receive(:abuse_detected?).and_return true
      expect(params).to receive_message_chain(:abuse_detection, :errors, :full_messages)
      search_service.abuse_messages
    end
  end

  describe 'abusive search handling' do
    subject { described_class.new(user, raw_params) }

    let(:raw_params) { { search: search, scope: scope } }
    let(:search) { 'foobar' }
    let(:search_service_double) { instance_double(Search::GlobalService) }

    before do
      allow(search_service).to receive_messages(search_service: search_service_double, search_type: 'basic')

      allow(Search::Params).to receive(:new)
        .with(raw_params, detect_abuse: true).and_call_original
    end

    context 'when a search is abusive' do
      let(:scope) { '1;drop%20table' }

      it 'does NOT execute search service' do
        expect(search_service_double).not_to receive(:execute)
        search_service.search_results
      end
    end

    context 'when a search is NOT abusive' do
      let(:scope) { 'work_items' }

      it 'executes search service' do
        expect(search_service_double).to receive(:execute)
        search_service.search_results
      end
    end
  end

  describe '.global_search_enabled_for_scope?' do
    using RSpec::Parameterized::TableSyntax
    let(:search) { 'foobar' }

    where(:scope, :admin_setting, :setting_enabled, :expected) do
      'work_items'     | :global_search_work_items_enabled     | false | false
      'work_items'     | :global_search_work_items_enabled     | true  | true
      'issues'         | :global_search_work_items_enabled     | false | false
      'issues'         | :global_search_work_items_enabled     | true  | true
      'merge_requests' | :global_search_merge_requests_enabled | false | false
      'merge_requests' | :global_search_merge_requests_enabled | true  | true
      'snippet_titles' | :global_search_snippet_titles_enabled | false | false
      'snippet_titles' | :global_search_snippet_titles_enabled | true  | true
      'users'          | :global_search_users_enabled          | false | false
      'users'          | :global_search_users_enabled          | true  | true
      'groups'         | :global_search_groups_enabled         | false | false
      'groups'         | :global_search_groups_enabled         | true  | true
      'random'         | :random                               | nil   | true
    end

    with_them do
      it 'returns false when feature_flag is not enabled and returns true when feature_flag is enabled' do
        stub_application_setting(admin_setting => setting_enabled)
        expect(search_service.global_search_enabled_for_scope?).to eq expected
      end
    end

    context 'when snippet search is enabled' do
      let(:scope) { 'snippet_titles' }

      before do
        allow(described_class).to receive(:show_snippets?).and_return(true)
      end

      it 'returns false when feature_flag is not enabled' do
        stub_application_setting(global_search_snippet_titles_enabled: false)

        expect(search_service.global_search_enabled_for_scope?).to be false
      end

      it 'returns true when feature_flag is enabled' do
        stub_application_setting(global_search_snippet_titles_enabled: true)

        expect(search_service.global_search_enabled_for_scope?).to be true
      end
    end

    context 'with API backward compatibility (skip_legacy_scope_conversion)' do
      let(:search) { 'foobar' }

      it 'checks work_items setting when scope is "issues"' do
        service = described_class.new(user, search: search, scope: 'issues', skip_legacy_scope_conversion: true)

        stub_application_setting(global_search_work_items_enabled: false)
        expect(service.global_search_enabled_for_scope?).to be false

        stub_application_setting(global_search_work_items_enabled: true)
        expect(service.global_search_enabled_for_scope?).to be true
      end
    end
  end

  describe '#abuse_detected?' do
    let(:instance) { described_class.new(nil, params) }
    let(:params) do
      { search: search }
    end

    context 'when params are abusive' do
      let(:search) { 'f' }

      it 'returns true and not checks for abusive_pipes' do
        expect(instance).not_to receive(:abusive_pipes?)
        expect(instance.abuse_detected?).to be true
      end
    end

    context 'when params are not abusive' do
      context 'when abuse_detection.abusive_pipes? returns true' do
        let(:search) { 'foo|f' }

        it 'returns true' do
          allow_next_instance_of(Gitlab::Search::AbuseDetection) do |instance|
            allow(instance).to receive(:abusive_pipes?).and_return(true)
          end
          expect(instance.abuse_detected?).to be true
        end
      end

      context 'when abuse_detection.abusive_pipes? returns false' do
        let(:search) { 'foo|bar' }

        it 'returns false' do
          allow(instance.params.abuse_detection).to receive(:abusive_pipes?).and_return(false)
          expect(instance.abuse_detected?).to be false
        end
      end
    end
  end

  describe 'user search redaction' do
    let_it_be(:unauthorized_user) { create(:user, username: 'unauthorized_user') }
    let(:search_results) { instance_double(Gitlab::SearchResults) }
    let(:mock_results) do
      [unauthorized_user].tap { |r| allow(r).to receive_messages(total_count: 1, limit_value: 20, offset_value: 0) }
    end

    before do
      allow(search_service).to receive(:search_results).and_return(search_results)
      allow(search_results).to receive(:objects).and_return(mock_results)
      allow(Ability).to receive(:allowed?).and_call_original
    end

    context 'when searching users at global level' do
      let(:search_service) { described_class.new(user, search: 'user', scope: 'users') }

      context 'when read_users_list permission is denied' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :read_users_list).and_return(false)
        end

        it 'redacts users' do
          results = search_service.search_objects

          expect(results).to be_empty
        end
      end

      context 'when read_users_list permission is granted' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :read_users_list).and_return(true)
        end

        it 'includes users' do
          results = search_service.search_objects

          expect(results).to include(unauthorized_user)
        end
      end
    end

    context 'when searching users at group level' do
      let(:search_service) { described_class.new(user, search: 'user', scope: 'users', group_id: accessible_group.id) }

      context 'when read_group_member permission is denied' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :read_group_member, accessible_group).and_return(false)
        end

        it 'redacts users' do
          results = search_service.search_objects

          expect(results).to be_empty
        end
      end

      context 'when read_group_member permission is granted' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :read_group_member, accessible_group).and_return(true)
        end

        it 'includes users' do
          results = search_service.search_objects

          expect(results).to include(unauthorized_user)
        end
      end
    end

    context 'when searching users at project level' do
      let(:search_service) do
        described_class.new(user, search: 'user', scope: 'users', project_id: accessible_project.id)
      end

      it 'always allows users since :read_project implies :read_project_member' do
        # No need to stub permissions - if user can access the project, they can see members
        results = search_service.search_objects

        expect(results).to include(unauthorized_user)
      end
    end
  end
end
