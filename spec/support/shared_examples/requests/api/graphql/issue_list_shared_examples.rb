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
