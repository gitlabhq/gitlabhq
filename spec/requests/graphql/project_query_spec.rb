require 'spec_helper'

describe 'getting project information' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository, :public) }

  let(:query) do
    <<~QUERY
    {
      project(full_path: "#{project.full_path}") {
        #{all_graphql_fields_for(Project)}
      }
    }
    QUERY
  end

  it_behaves_like 'a working graphql query' do
    it 'renders a project with all fields' do
      expect(response_data['project']).not_to be_nil
    end
  end
end
