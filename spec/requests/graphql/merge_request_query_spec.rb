require 'spec_helper'

describe 'getting merge request information' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository, :public) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  let(:query) do
    <<~QUERY
    {
      merge_request(project: "#{merge_request.project.full_path}", iid: "#{merge_request.iid}") {
        #{all_graphql_fields_for(MergeRequest)}
      }
    }
    QUERY
  end

  it_behaves_like 'a working graphql query' do
    it 'renders a merge request with all fields' do
      expect(response_data['merge_request']).not_to be_nil
    end
  end
end
