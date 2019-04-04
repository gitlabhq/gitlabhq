require 'spec_helper'

describe 'GitlabSchema configurations' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository) }
  let!(:query)  { graphql_query_for('project', 'fullPath' => project.full_path) }

  it 'shows an error if complexity it too high' do
    allow(GitlabSchema).to receive(:max_query_complexity).and_return 1

    post_graphql(query, current_user: nil)

    expect(graphql_errors.first['message']).to include('which exceeds max complexity of 1')
  end
end
