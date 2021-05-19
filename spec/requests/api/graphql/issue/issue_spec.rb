# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.issue(id)' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:issue_params) { { 'id' => issue.to_global_id.to_s } }

  let(:issue_data) { graphql_data['issue'] }
  let(:issue_fields) { all_graphql_fields_for('Issue'.classify) }

  let(:query) do
    graphql_query_for('issue', issue_params, issue_fields)
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  it_behaves_like 'a noteable graphql type we can query' do
    let(:noteable) { issue }
    let(:project) { issue.project }
    let(:path_to_noteable) { [:issue] }

    before do
      project.add_guest(current_user)
    end

    def query(fields)
      graphql_query_for('issue', issue_params, fields)
    end
  end

  context 'when the user does not have access to the issue' do
    it 'returns nil' do
      project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)

      post_graphql(query)

      expect(issue_data).to be nil
    end
  end

  context 'when the user does have access' do
    before do
      project.add_guest(current_user)
    end

    it 'returns the issue' do
      post_graphql(query, current_user: current_user)

      expect(issue_data).to include(
        'title' => issue.title,
        'description' => issue.description
      )
    end

    context 'when selecting any single field' do
      where(:field) do
        scalar_fields_of('Issue').map { |name| [name] }
      end

      with_them do
        it_behaves_like 'a working graphql query' do
          let(:issue_fields) do
            field
          end

          before do
            post_graphql(query, current_user: current_user)
          end

          it "returns the issue and field #{params['field']}" do
            expect(issue_data.keys).to eq([field])
          end
        end
      end
    end

    context 'when selecting multiple fields' do
      let(:issue_fields) { ['title', 'description', 'updatedBy { username }'] }

      it 'returns the issue with the specified fields' do
        post_graphql(query, current_user: current_user)

        expect(issue_data.keys).to eq %w[title description updatedBy]
        expect(issue_data['title']).to eq(issue.title)
        expect(issue_data['description']).to eq(issue.description)
        expect(issue_data['updatedBy']['username']).to eq(issue.author.username)
      end
    end

    context 'when issue got moved' do
      let_it_be(:issue_fields) { ['moved', 'movedTo { title }'] }
      let_it_be(:new_issue) { create(:issue) }
      let_it_be(:issue) { create(:issue, project: project, moved_to: new_issue) }
      let_it_be(:issue_params) { { 'id' => issue.to_global_id.to_s } }

      before_all do
        new_issue.project.add_developer(current_user)
      end

      it 'returns correct attributes' do
        post_graphql(query, current_user: current_user)

        expect(issue_data.keys).to eq %w[moved movedTo]
        expect(issue_data['moved']).to eq(true)
        expect(issue_data['movedTo']['title']).to eq(new_issue.title)
      end
    end

    context 'when passed a non-issue gid' do
      let(:mr) { create(:merge_request) }

      it 'returns an error' do
        gid = mr.to_global_id.to_s
        issue_params['id'] = gid

        post_graphql(query, current_user: current_user)

        expect(graphql_errors).not_to be nil
        expect(graphql_errors.first['message']).to eq("\"#{gid}\" does not represent an instance of Issue")
      end
    end
  end

  context 'when there is a confidential issue' do
    let!(:confidential_issue) do
      create(:issue, :confidential, project: project)
    end

    let(:issue_params) { { 'id' => confidential_issue.to_global_id.to_s } }

    context 'when the user cannot see confidential issues' do
      it 'returns nil' do
        post_graphql(query, current_user: current_user)

        expect(issue_data).to be nil
      end
    end

    context 'when the user can see confidential issues' do
      it 'returns the confidential issue' do
        project.add_developer(current_user)

        post_graphql(query, current_user: current_user)

        expect(graphql_data.count).to eq(1)
        expect(issue_data['confidential']).to be(true)
      end
    end
  end
end
