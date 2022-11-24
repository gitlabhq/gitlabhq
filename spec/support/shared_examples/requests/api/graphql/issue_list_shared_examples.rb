# frozen_string_literal: true

RSpec.shared_examples 'graphql issue list request spec' do
  it_behaves_like 'a working graphql query' do
    before do
      post_query
    end
  end

  describe 'filters' do
    context 'when filtering by assignees' do
      context 'when both assignee_username filters are provided' do
        let(:issue_filter_params) do
          { assignee_username: current_user.username, assignee_usernames: [current_user.username] }
        end

        it 'returns a mutually exclusive param error' do
          post_query

          expect_graphql_errors_to_include(
            'only one of [assigneeUsernames, assigneeUsername] arguments is allowed at the same time.'
          )
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
      let(:issue_filter_params) { { or: { assignee_usernames: [current_user.username, another_user.username] } } }

      it 'returns correctly filtered issues' do
        post_query

        expect(issue_ids).to match_array(expected_unioned_assignee_issues.map { |i| i.to_gid.to_s })
      end

      context 'when argument is blank' do
        let(:issue_filter_params) { { or: {} } }

        it 'does not raise an error' do
          post_query

          expect_graphql_errors_to_be_empty
        end
      end

      context 'when feature flag is disabled' do
        it 'returns an error' do
          stub_feature_flags(or_issuable_queries: false)

          post_query

          expect_graphql_errors_to_include(
            "'or' arguments are only allowed when the `or_issuable_queries` feature flag is enabled."
          )
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
        'thumbsup'   | lazy { voted_issues }
        'ANY'        | lazy { voted_issues }
        'any'        | lazy { voted_issues }
        'AnY'        | lazy { voted_issues }
        'NONE'       | lazy { no_award_issues }
        'thumbsdown' | lazy { [] }
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
  end

  describe 'sorting and pagination' do
    context 'when sorting by severity' do
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

  context 'when confidential issues exist' do
    context 'when user can see confidential issues' do
      it 'includes confidential issues' do
        post_query

        all_issues = confidential_issues + non_confidential_issues

        expect(issue_ids).to match_array(to_gid_list(all_issues))
        expect(issues_data.map { |i| i['confidential'] }).to match_array(all_issues.map(&:confidential))
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

  context 'when fetching escalation status' do
    let_it_be(:escalation_status) { create(:incident_management_issuable_escalation_status, issue: issue_a) }

    let(:fields) do
      <<~QUERY
        nodes {
          id
          escalationStatus
        }
      QUERY
    end

    before do
      issue_a.update_columns(issue_type: Issue.issue_types[:incident])
    end

    it 'returns the escalation status values' do
      post_query

      statuses = issues_data.map { |issue| issue['escalationStatus'] }

      expect(statuses).to contain_exactly(escalation_status.status_name.upcase.to_s, nil, nil, nil, nil)
    end

    it 'avoids N+1 queries', :aggregate_failures do
      control = ActiveRecord::QueryRecorder.new { run_with_clean_state(query, context: { current_user: current_user }) }

      new_incident = create(:incident, project: public_projects.first)
      create(:incident_management_issuable_escalation_status, issue: new_incident)

      expect { run_with_clean_state(query, context: { current_user: current_user }) }.not_to exceed_query_limit(control)
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
end
