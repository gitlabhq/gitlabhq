# frozen_string_literal: true

RSpec.shared_examples 'graphql issue list request spec' do
  let(:issue_ids) { graphql_dig_at(issues_data, :id) }
  let(:fields) do
    <<~QUERY
    nodes {
      #{all_graphql_fields_for('issues'.classify, excluded: %w[relatedMergeRequests productAnalyticsState])}
    }
    QUERY
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_query
    end
  end

  describe 'filters' do
    let(:mutually_exclusive_error) do
      'Only one of [assigneeUsernames, assigneeUsername, assigneeWildcardId] arguments is allowed at the same time.'
    end

    before_all do
      issue_a.assignee_ids = current_user.id
      issue_b.assignee_ids = another_user.id
    end

    context 'when filtering by state' do
      context 'when filtering by locked state' do
        let(:issue_filter_params) { { state: :locked } }

        it 'returns an error message' do
          post_query

          expect_graphql_errors_to_include(Types::IssuableStateEnum::INVALID_LOCKED_MESSAGE)
        end
      end
    end

    context 'when filtering by milestone' do
      context 'when both negated milestone_id and milestone_wildcard_id filters are provided' do
        let(:issue_filter_params) do
          { not: { milestone_title: 'some_milestone', milestone_wildcard_id: :STARTED } }
        end

        it 'returns a mutually exclusive param error' do
          post_query

          expect_graphql_errors_to_include(
            'Only one of [milestoneTitle, milestoneWildcardId] arguments is allowed at the same time.'
          )
        end
      end
    end

    context 'when filtering by assignees' do
      context 'when both assignee_username filters are provided' do
        let(:issue_filter_params) do
          { assignee_username: current_user.username, assignee_usernames: [current_user.username] }
        end

        it 'returns a mutually exclusive param error' do
          post_query

          expect_graphql_errors_to_include(mutually_exclusive_error)
        end
      end

      context 'when both assignee_username and assignee_wildcard_id filters are provided' do
        let(:issue_filter_params) do
          { assignee_username: current_user.username, assignee_wildcard_id: :ANY }
        end

        it 'returns a mutually exclusive param error' do
          post_query

          expect_graphql_errors_to_include(mutually_exclusive_error)
        end
      end

      context 'when filtering by assignee_wildcard_id' do
        context 'when filtering for all issues with assignees' do
          let(:issue_filter_params) do
            { assignee_wildcard_id: :ANY }
          end

          it 'returns all issues with assignees' do
            post_query

            expect(issue_ids).to match_array([issue_a, issue_b].map { |i| i.to_gid.to_s })
          end
        end

        context 'when filtering for issues without assignees' do
          let(:issue_filter_params) do
            { assignee_wildcard_id: :NONE }
          end

          it 'returns all issues without assignees' do
            post_query

            expect(issue_ids).to match_array([issue_c, issue_d, issue_e].map { |i| i.to_gid.to_s })
          end
        end
      end

      context 'when filtering by a negated argument' do
        let(:issue_filter_params) { { not: { assignee_usernames: [current_user.username] } } }

        it 'returns correctly filtered issues' do
          post_query

          expect(issue_ids).to match_array(expected_negated_assignee_issues.map { |i| i.to_gid.to_s })
        end
      end
    end

    context 'when filtering by unioned arguments' do
      context 'when filtering by assignees' do
        let(:issue_filter_params) { { or: { assignee_usernames: [current_user.username, another_user.username] } } }

        it 'returns correctly filtered issues' do
          post_query

          expect(issue_ids).to match_array([issue_a, issue_b].map { |i| i.to_gid.to_s })
        end
      end

      context 'when filtering by labels' do
        let_it_be(:label_a) { create(:label, project: issue_a.project) }
        let_it_be(:label_b) { create(:label, project: issue_b.project) }

        let(:issue_filter_params) { { or: { label_names: [label_a.title, label_b.title] } } }

        it 'returns correctly filtered issues' do
          issue_a.label_ids = label_a.id
          issue_b.label_ids = label_b.id

          post_graphql(query, current_user: current_user)

          expect(issue_ids).to match_array([issue_a, issue_b].map { |i| i.to_gid.to_s })
        end
      end

      context 'when argument is blank' do
        let(:issue_filter_params) { { or: {} } }

        it 'does not raise an error' do
          post_query

          expect_graphql_errors_to_be_empty
        end
      end
    end

    context 'when filtering by a blank negated argument' do
      let(:issue_filter_params) { { not: {} } }

      it 'does not raise an error' do
        post_query

        expect_graphql_errors_to_be_empty
      end
    end

    context 'when filtering by reaction emoji' do
      using RSpec::Parameterized::TableSyntax

      where(:value, :issue_list) do
        AwardEmoji::THUMBS_UP   | lazy { voted_issues }
        'ANY'                   | lazy { voted_issues }
        'any'                   | lazy { voted_issues }
        'AnY'                   | lazy { voted_issues }
        'NONE'                  | lazy { no_award_issues }
        AwardEmoji::THUMBS_DOWN | lazy { [] }
      end

      with_them do
        let(:issue_filter_params) { { my_reaction_emoji: value } }
        let(:gids) { to_gid_list(issue_list) }

        it 'returns correctly filtered issues' do
          post_query

          expect(issue_ids).to match_array(gids)
        end
      end
    end

    context 'when filtering by search' do
      it_behaves_like 'query with a search term', [:TITLE] do
        let(:search_term) { search_title_term }
        let(:issuable_data) { issues_data }
        let(:user) { current_user }
        let(:issuable) { title_search_issue }
        let(:ids) { issue_ids }
      end
    end

    context 'when filtering by subscribed' do
      context 'with no filtering' do
        it 'returns all items' do
          post_query

          expect(issue_ids).to match_array(to_gid_list(issues))
        end
      end

      context 'with user filters for subscribed items' do
        let(:issue_filter_params) { { subscribed: :EXPLICITLY_SUBSCRIBED } }

        it 'returns only subscribed items' do
          post_query

          expect(issue_ids).to match_array(to_gid_list(subscribed_issues))
        end
      end

      context 'with user filters out subscribed items' do
        let(:issue_filter_params) { { subscribed: :EXPLICITLY_UNSUBSCRIBED } }

        it 'returns only unsubscribed items' do
          post_query

          expect(issue_ids).to match_array(to_gid_list(unsubscribed_issues))
        end
      end
    end

    context 'when filtering by confidentiality' do
      context 'when fetching confidential issues' do
        let(:issue_filter_params) { { confidential: true } }

        it 'returns only confidential issues' do
          post_query

          expect(issue_ids).to match_array(to_gid_list(confidential_issues))
        end

        context 'when user cannot see confidential issues' do
          it 'returns an empty list' do
            post_query(external_user)

            expect(issue_ids).to be_empty
          end
        end
      end

      context 'when fetching non-confidential issues' do
        let(:issue_filter_params) { { confidential: false } }

        it 'returns only non-confidential issues' do
          post_query

          expect(issue_ids).to match_array(to_gid_list(non_confidential_issues))
        end

        context 'when user cannot see confidential issues' do
          it 'returns an empty list' do
            post_query(external_user)

            expect(issue_ids).to match_array(to_gid_list(public_non_confidential_issues))
          end
        end
      end
    end

    # Querying Service Desk issues uses `support-bot` `author_username`.
    # This is a workaround that selects both legacy Service Desk issues and ticket work items
    # until we migrated Service Desk issues to work items of type ticket.
    # Will be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/505024
    context 'when filtering by Service Desk issues/tickets' do
      # Use items only for this context because it's temporary. This way we don't need to modify other examples.
      let_it_be(:service_desk_issue) { create(:issue, project: project, author: ::Users::Internal.support_bot) }
      # don't use support bot because this isn't a req for ticket WIT
      let_it_be(:ticket) { create(:work_item, :ticket, project: project, author: current_user) }
      # Get work item as issue because this query only returns issues.
      let_it_be(:service_desk_items) { [service_desk_issue, Issue.find(ticket.id)] }

      let_it_be(:base_params) { { iids: service_desk_items.map { |issue| issue.iid.to_s } } }

      let(:issue_filter_params) { { author_username: 'support-bot' } }

      it 'returns Service Desk issue and ticket work item' do
        post_query

        expect(issue_ids).to match_array(to_gid_list(service_desk_items))
      end
    end
  end

  describe 'sorting and pagination' do
    context 'when sorting by severity' do
      let(:expected_severity_sorted_asc) { [issue_c, issue_a, issue_b, issue_e, issue_d] }

      before_all do
        create(:issuable_severity, issue: issue_a, severity: :unknown)
        create(:issuable_severity, issue: issue_b, severity: :low)
        create(:issuable_severity, issue: issue_d, severity: :critical)
        create(:issuable_severity, issue: issue_e, severity: :high)
      end

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)  { :SEVERITY_ASC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list(expected_severity_sorted_asc) }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)  { :SEVERITY_DESC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list(expected_severity_sorted_asc.reverse) }
        end
      end
    end

    context 'when sorting by priority' do
      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)  { :PRIORITY_ASC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list(expected_priority_sorted_asc) }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)  { :PRIORITY_DESC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list(expected_priority_sorted_desc) }
        end
      end
    end

    context 'when sorting by due date' do
      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)  { :DUE_DATE_ASC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list(expected_due_date_sorted_asc) }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)  { :DUE_DATE_DESC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list(expected_due_date_sorted_desc) }
        end
      end
    end

    context 'when sorting by relative position' do
      context 'when ascending' do
        it_behaves_like 'sorted paginated query', is_reversible: true do
          let(:sort_param)  { :RELATIVE_POSITION_ASC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list(expected_relative_position_sorted_asc) }
        end
      end
    end

    context 'when sorting by label priority' do
      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { :LABEL_PRIORITY_ASC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list(expected_label_priority_sorted_asc) }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { :LABEL_PRIORITY_DESC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list(expected_label_priority_sorted_desc) }
        end
      end
    end

    context 'when sorting by milestone due date' do
      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { :MILESTONE_DUE_ASC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list(expected_milestone_sorted_asc) }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { :MILESTONE_DUE_DESC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list(expected_milestone_sorted_desc) }
        end
      end
    end
  end

  describe 'N+1 query checks' do
    let(:extra_iid_for_second_query) { issue_b.iid.to_s }
    let(:search_params) { { iids: [issue_a.iid.to_s] } }
    let(:issue_filter_params) { search_params }
    let(:fields) do
      <<~QUERY
        nodes {
          id
          #{requested_fields}
        }
      QUERY
    end

    def execute_query
      post_query
    end

    context 'when requesting `user_notes_count` and `user_discussions_count`',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/448559' do
      let(:requested_fields) { 'userNotesCount userDiscussionsCount' }

      before do
        create_list(:note_on_issue, 2, noteable: issue_a, project: issue_a.project)
        create(:note_on_issue, noteable: issue_b, project: issue_b.project)
      end

      include_examples 'N+1 query check'
    end

    context 'when requesting `merge_requests_count`' do
      let(:requested_fields) { 'mergeRequestsCount' }

      before do
        create_list(:merge_requests_closing_issues, 2, issue: issue_a)
        create_list(:merge_requests_closing_issues, 3, issue: issue_b)
      end

      include_examples 'N+1 query check'
    end

    context 'when requesting `timelogs`', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/448337' do
      let(:requested_fields) { 'timelogs { nodes { timeSpent } }' }

      before do
        create_list(:issue_timelog, 2, issue: issue_a)
        create(:issue_timelog, issue: issue_b)
      end

      include_examples 'N+1 query check'
    end

    context 'when requesting `closed_as_duplicate_of`' do
      let(:requested_fields) { 'closedAsDuplicateOf { id }' }
      let(:issue_a_dup) { create(:issue, project: issue_a.project) }
      let(:issue_b_dup) { create(:issue, project: issue_b.project) }

      before do
        issue_a.update!(duplicated_to_id: issue_a_dup)
        issue_b.update!(duplicated_to_id: issue_a_dup)
      end

      include_examples 'N+1 query check'
    end

    context 'when award emoji votes' do
      let(:requested_fields) { 'upvotes downvotes' }

      before do
        create_list(:award_emoji, 2, name: AwardEmoji::THUMBS_UP, awardable: issue_a)
        create_list(:award_emoji, 2, name: AwardEmoji::THUMBS_DOWN, awardable: issue_b)
      end

      include_examples 'N+1 query check'
    end

    context 'when requesting labels', :use_sql_query_cache do
      let(:requested_fields) { 'labels { nodes { id } }' }
      let(:extra_iid_for_second_query) { same_project_issue2.iid.to_s }
      let(:search_params) { { iids: [same_project_issue1.iid.to_s] } }

      before do
        current_project = same_project_issue1.project
        project_labels = create_list(:label, 2, project: current_project)
        group_labels = create_list(:group_label, 2, group: current_project.group)

        same_project_issue1.update!(labels: [project_labels.first, group_labels.first].flatten)
        same_project_issue2.update!(labels: [project_labels, group_labels].flatten)
      end

      include_examples 'N+1 query check', skip_cached: false
    end
  end

  context 'when confidential issues exist' do
    context 'when user can see confidential issues' do
      it 'includes confidential issues' do
        post_query

        all_issues = confidential_issues + non_confidential_issues

        expect(issue_ids).to match_array(to_gid_list(all_issues))
        expect(issues_data.pluck('confidential')).to match_array(all_issues.map(&:confidential))
      end
    end

    context 'when user cannot see confidential issues' do
      let(:current_user) { external_user }

      it 'does not include confidential issues' do
        post_query

        expect(issue_ids).to match_array(to_gid_list(public_non_confidential_issues))
      end
    end
  end

  context 'when limiting the number of results' do
    let(:issue_limit) { 1 }
    let(:issue_filter_params) { { first: issue_limit } }

    it_behaves_like 'a working graphql query' do
      before do
        post_query
      end

      it 'only returns N issues' do
        expect(issues_data.size).to eq(issue_limit)
      end
    end

    context 'when no limit is provided' do
      let(:issue_limit) { nil }

      it 'returns all issues' do
        post_query

        expect(issues_data.size).to be > 1
      end
    end

    it 'is expected to check permissions on the first issue only' do
      allow(Ability).to receive(:allowed?).and_call_original
      # Newest first, we only want to see the newest checked
      expect(Ability).not_to receive(:allowed?).with(current_user, :read_issue, issues.first)

      post_query
    end
  end

  context 'when the user does not have access to the issue' do
    let(:current_user) { external_user }

    it 'returns no issues' do
      public_projects.each do |public_project|
        public_project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
      end

      post_query

      expect(issues_data).to eq([])
    end
  end

  context 'when fetching external participants' do
    before_all do
      issue_a.update!(external_author: 'user@example.com')
    end

    let(:fields) do
      <<~QUERY
        nodes {
          id
          externalAuthor
        }
      QUERY
    end

    it 'returns the email address' do
      post_query

      emails = issues_data.pluck('externalAuthor').compact
      expect(emails).to contain_exactly('user@example.com')
    end

    context 'when user does not have access to view emails' do
      let(:current_user) { external_user }

      it 'obfuscates the email address' do
        post_query

        emails = issues_data.pluck('externalAuthor').compact
        expect(emails).to contain_exactly("us*****@e*****.c**")
      end
    end
  end

  context 'when fetching escalation status' do
    let_it_be(:escalation_status) { create(:incident_management_issuable_escalation_status, issue: issue_a) }
    let_it_be(:incident_type) { WorkItems::Type.default_by_type(:incident) }

    let(:fields) do
      <<~QUERY
        nodes {
          id
          escalationStatus
        }
      QUERY
    end

    before do
      issue_a.update_columns(work_item_type_id: incident_type.id)
    end

    it 'returns the escalation status values' do
      post_query

      statuses = issues_data.pluck('escalationStatus')

      expect(statuses).to contain_exactly(escalation_status.status_name.upcase.to_s, nil, nil, nil, nil)
    end

    it 'avoids N+1 queries', :aggregate_failures do
      control = ActiveRecord::QueryRecorder.new { run_with_clean_state(query, context: { current_user: current_user }) }

      new_incident = create(:incident, project: public_projects.first)
      create(:incident_management_issuable_escalation_status, issue: new_incident)

      expect { run_with_clean_state(query, context: { current_user: current_user }) }.not_to exceed_query_limit(control)
    end
  end

  context 'when fetching alert management alert' do
    let(:fields) do
      <<~QUERY
        nodes {
          iid
          alertManagementAlert {
            title
          }
          alertManagementAlerts {
            nodes {
              title
            }
          }
        }
      QUERY
    end

    it 'avoids N+1 queries' do
      control = ActiveRecord::QueryRecorder.new { post_query }

      create(:alert_management_alert, :with_incident, project: public_projects.first)

      expect { post_query }.not_to exceed_query_limit(control)
    end

    it 'returns the alert data' do
      post_query

      alert_titles = issues_data.map { |issue| issue.dig('alertManagementAlert', 'title') }
      expected_titles = issues.map { |issue| issue.alert_management_alerts.first&.title }

      expect(alert_titles).to contain_exactly(*expected_titles)
    end

    it 'returns the alerts data' do
      post_query

      alert_titles = issues_data.map { |issue| issue.dig('alertManagementAlerts', 'nodes') }
      expected_titles = issues.map do |issue|
        issue.alert_management_alerts.map { |alert| { 'title' => alert.title } }
      end

      expect(alert_titles).to contain_exactly(*expected_titles)
    end
  end

  context 'when fetching customer_relations_contacts' do
    let(:fields) do
      <<~QUERY
      nodes {
        id
        customerRelationsContacts {
          nodes {
            firstName
          }
        }
      }
      QUERY
    end

    def clean_state_query
      run_with_clean_state(query, context: { current_user: current_user })
    end

    it 'avoids N+1 queries' do
      create(:issue_customer_relations_contact, :for_issue, issue: issue_a)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { clean_state_query }

      create(:issue_customer_relations_contact, :for_issue, issue: issue_a)

      expect { clean_state_query }.not_to exceed_all_query_limit(control)
    end
  end

  context 'when fetching labels' do
    let(:fields) do
      <<~QUERY
        nodes {
          id
          labels {
            nodes {
              id
            }
          }
        }
      QUERY
    end

    before do
      issues.each do |issue|
        # create a label for each issue we have to properly test N+1
        label = create(:label, project: issue.project)
        issue.update!(labels: [label])
      end
    end

    def response_label_ids(response_data)
      response_data.flat_map do |node|
        node['labels']['nodes'].pluck('id')
      end
    end

    def labels_as_global_ids(issues)
      issues.flat_map { |issue| issue.labels.map { |label| label.to_global_id.to_s } }
    end

    it 'avoids N+1 queries', :aggregate_failures do
      control = ActiveRecord::QueryRecorder.new { post_query }
      expect(issues_data.count).to eq(5)
      expect(response_label_ids(issues_data)).to match_array(labels_as_global_ids(issues))

      public_project = public_projects.first
      new_issues = issues + [
        create(:issue, project: public_project, labels: [create(:label, project: public_project)])
      ]

      expect { post_query }.not_to exceed_query_limit(control)

      expect(issues_data.count).to eq(6)
      expect(response_label_ids(issues_data)).to match_array(labels_as_global_ids(new_issues))
    end
  end

  context 'when fetching assignees' do
    let(:fields) do
      <<~QUERY
        nodes {
          id
          assignees {
            nodes {
              id
            }
          }
        }
      QUERY
    end

    before do
      issues.each do |issue|
        # create an assignee for each issue we have to properly test N+1
        assignee = create(:user)
        issue.update!(assignees: [assignee])
      end
    end

    def response_assignee_ids(response_data)
      response_data.flat_map do |node|
        node['assignees']['nodes'].pluck('id')
      end
    end

    def assignees_as_global_ids(issues)
      issues.flat_map(&:assignees).map(&:to_global_id).map(&:to_s)
    end

    it 'avoids N+1 queries', :aggregate_failures do
      control = ActiveRecord::QueryRecorder.new { post_query }
      expect(issues_data.count).to eq(5)
      expect(response_assignee_ids(issues_data)).to match_array(assignees_as_global_ids(issues))

      public_project = public_projects.first
      new_issues = issues + [create(:issue, project: public_project, assignees: [create(:user)])]

      expect { post_query }.not_to exceed_query_limit(control)

      expect(issues_data.count).to eq(6)
      expect(response_assignee_ids(issues_data)).to match_array(assignees_as_global_ids(new_issues))
    end
  end

  context 'when selecting `related_merge_requests`' do
    let(:fields) do
      <<~QUERY
      nodes {
        relatedMergeRequests {
          nodes {
            id
          }
        }
      }
      QUERY
    end

    it 'limits the field to 1 execution' do
      post_query

      expect_graphql_errors_to_include(
        '"relatedMergeRequests" field can be requested only for 1 Issue(s) at a time.'
      )
    end
  end

  it 'includes a web_url' do
    post_query

    expect(issues_data[0]['webUrl']).to be_present
  end

  it 'includes discussion locked' do
    post_query

    expect(issues_data).to contain_exactly(
      *locked_discussion_issues.map { |i| hash_including('id' => i.to_gid.to_s, 'discussionLocked' => true) },
      *unlocked_discussion_issues.map { |i| hash_including('id' => i.to_gid.to_s, 'discussionLocked' => false) }
    )
  end

  def to_gid_list(instance_list)
    instance_list.map { |instance| instance.to_gid.to_s }
  end

  def issues_data
    graphql_data.dig(*issue_nodes_path)
  end
end
