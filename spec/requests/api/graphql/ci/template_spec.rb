# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Querying CI template' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  let(:query) do
    <<~QUERY
    {
      project(fullPath: "#{project.full_path}") {
        name
        ciTemplate(name: "#{template_name}") {
          name
          content
        }
      }
    }
    QUERY
  end

  before do
    post_graphql(query, current_user: user)
  end

  context 'when the template exists' do
    let(:template_name) { 'Android' }

    it_behaves_like 'a working graphql query'

    it 'returns correct data' do
      expect(graphql_data.dig('project', 'ciTemplate', 'name')).to eq(template_name)
      expect(graphql_data.dig('project', 'ciTemplate', 'content')).not_to be_blank
    end
  end

  context 'when the template does not exist' do
    let(:template_name) { 'doesnotexist' }

    it_behaves_like 'a working graphql query'

    it 'returns correct data' do
      expect(graphql_data.dig('project', 'ciTemplate')).to eq(nil)
    end
  end
end
