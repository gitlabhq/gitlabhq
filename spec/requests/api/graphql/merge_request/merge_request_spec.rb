# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.merge_request(id)', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :empty_repo) }
  # freeze: false because creating notes on the merge request touches the
  # noteable (Note#touch_noteable), which would raise FrozenError on a frozen
  # let_it_be record once ThrottledTouch's interval has elapsed.
  let_it_be(:merge_request, freeze: false) { create(:merge_request, source_project: project) }
  let_it_be(:current_user) { create(:user) }

  let(:merge_request_params) { { 'id' => global_id_of(merge_request) } }
  let(:merge_request_data) { graphql_data['mergeRequest'] }
  let(:merge_request_fields) { all_graphql_fields_for('MergeRequest'.classify) }

  let(:query) do
    graphql_query_for('mergeRequest', merge_request_params, merge_request_fields)
  end

  context 'when the user does not have access to the merge request' do
    it_behaves_like 'a working graphql query that returns no data' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end
  end

  context 'when the user does have access' do
    before do
      project.add_reporter(current_user)
    end

    it_behaves_like 'a noteable graphql type we can query' do
      let(:noteable) { merge_request }
      let(:project) { merge_request.project }
      let(:path_to_noteable) { [:merge_request] }

      def query(fields)
        graphql_query_for('mergeRequest', merge_request_params, fields)
      end
    end

    it 'returns the merge request' do
      post_graphql(query, current_user: current_user)

      expect(merge_request_data).to include(
        'title' => merge_request.title,
        'description' => merge_request.description
      )
    end

    context 'when selecting any single field' do
      where(:field) do
        scalar_fields_of('MergeRequest').map { |name| [name] }
      end

      with_them do
        it_behaves_like 'a working graphql query that returns data' do
          let(:merge_request_fields) do
            field
          end

          before do
            post_graphql(query, current_user: current_user)
          end

          it "returns the merge request and field #{params['field']}" do
            expect(merge_request_data.keys).to eq([field])
          end
        end
      end
    end

    context 'when selecting multiple fields' do
      let(:merge_request_fields) { ['title', 'description', 'author { username }'] }

      it 'returns the merge request with the specified fields' do
        post_graphql(query, current_user: current_user)

        expect(merge_request_data.keys).to eq %w[title description author]
        expect(merge_request_data['title']).to eq(merge_request.title)
        expect(merge_request_data['description']).to eq(merge_request.description)
        expect(merge_request_data['author']['username']).to eq(merge_request.author.username)
      end
    end

    describe 'discussionsWithActivity' do
      let_it_be(:label) { create(:label, project: project) }
      let_it_be(:milestone) { create(:milestone, project: project) }

      let_it_be(:user_comment) do
        create(:note, noteable: merge_request, project: project, note: 'a user comment')
      end

      let_it_be(:label_event) do
        create(:resource_label_event, merge_request: merge_request, label: label, action: 'add')
      end

      let_it_be(:milestone_event) do
        create(:resource_milestone_event, merge_request: merge_request, milestone: milestone, action: 'add')
      end

      let_it_be(:state_event) do
        create(:resource_state_event, merge_request: merge_request, state: :closed)
      end

      def notes_for(field_selection, field_key)
        post_graphql(
          graphql_query_for('mergeRequest', merge_request_params, field_selection),
          current_user: current_user
        )

        graphql_dig_at(merge_request_data, field_key, :nodes)
          .flat_map { |discussion| discussion['notes']['nodes'] }
      end

      it 'includes synthetic resource-event notes alongside user comments', :aggregate_failures do
        notes = notes_for(<<~GRAPHQL, :discussions_with_activity)
          discussionsWithActivity(first: 20) {
            nodes { notes { nodes { body system } } }
          }
        GRAPHQL

        expect(notes).to include(a_hash_including('body' => 'a user comment', 'system' => false))

        system_bodies = notes.select { |note| note['system'] }.map { |note| note['body'] }

        expect(system_bodies).to include(
          a_string_matching(/added .*label/),
          a_string_matching(/changed milestone to/),
          a_string_matching(/\Aclosed/)
        )
      end

      it 'excludes synthetic notes when filtering to comments only', :aggregate_failures do
        notes = notes_for(<<~GRAPHQL, :discussions_with_activity)
          discussionsWithActivity(first: 20, filter: ONLY_COMMENTS) {
            nodes { notes { nodes { body system } } }
          }
        GRAPHQL

        expect(notes).to all(include('system' => false))
        expect(notes.map { |note| note['body'] }).to include('a user comment')
      end

      it 'are absent from the standard discussions field', :aggregate_failures do
        notes = notes_for(<<~GRAPHQL, :discussions)
          discussions(first: 20) {
            nodes { notes { nodes { body system } } }
          }
        GRAPHQL

        bodies = notes.map { |note| note['body'] }

        expect(bodies).to include('a user comment')
        expect(bodies).not_to include(a_string_matching(/added .*label/))
      end
    end

    context 'when passed a non-merge request gid' do
      let(:issue) { create(:issue) }

      it 'returns an error' do
        gid = issue.to_global_id.to_s
        merge_request_params['id'] = gid

        post_graphql(query, current_user: current_user)

        expect(graphql_errors).not_to be_nil
        expect(graphql_errors.first['message']).to eq("\"#{gid}\" does not represent an instance of MergeRequest")
      end
    end
  end
end
