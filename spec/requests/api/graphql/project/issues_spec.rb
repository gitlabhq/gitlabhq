require 'spec_helper'

describe 'getting an issue list for a project' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository, :public) }
  let(:current_user) { create(:user) }
  let(:issues_data) { graphql_data['project']['issues']['edges'] }
  let!(:issues) do
    create(:issue, project: project, discussion_locked: true)
    create(:issue, project: project)
  end
  let(:fields) do
    <<~QUERY
    edges {
      node {
        #{all_graphql_fields_for('issues'.classify)}
      }
    }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('issues', {}, fields)
    )
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  it 'includes a web_url' do
    post_graphql(query, current_user: current_user)

    expect(issues_data[0]['node']['webUrl']).to be_present
  end

  it 'includes discussion locked' do
    post_graphql(query, current_user: current_user)

    expect(issues_data[0]['node']['discussionLocked']).to eq false
    expect(issues_data[1]['node']['discussionLocked']).to eq true
  end

  context 'when the user does not have access to the issue' do
    it 'returns nil' do
      project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)

      post_graphql(query)

      expect(issues_data).to eq []
    end
  end
end
