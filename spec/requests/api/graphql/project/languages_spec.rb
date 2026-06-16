# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project.languages', feature_category: :internationalization do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project, freeze: false) { create(:project, :public, :repository) }
  let_it_be(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          languages {
            name
            share
            color
          }
        }
      }
    )
  end

  let_it_be(:test_languages) do
    [{ value: 66.69, label: "Ruby", color: "#701516", highlight: "#701516" },
      { value: 22.98, label: "JavaScript", color: "#f1e05a", highlight: "#f1e05a" },
      { value: 7.91, label: "HTML", color: "#e34c26", highlight: "#e34c26" },
      { value: 2.42, label: "CoffeeScript", color: "#244776", highlight: "#244776" }]
  end

  let_it_be(:expected_languages) do
    test_languages.map { |lang| { 'name' => lang[:label], 'share' => lang[:value], 'color' => lang[:color] } }
  end

  before do
    allow(project.repository).to receive(:languages).and_return(test_languages)
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', [:read_project, :read_language] do
    let(:user) { create(:user, developer_of: project) }
    let(:boundary_object) { project }
    let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
  end

  context "when the languages haven't been detected yet" do
    it 'returns expected languages on second request as detection is done asynchronously', :sidekiq_inline do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:project, :languages)).to eq([])

      post_graphql(query, current_user: user)

      expect(graphql_data_at(:project, :languages)).to eq(expected_languages)
    end
  end

  context 'when the languages were detected before' do
    before do
      Projects::DetectRepositoryLanguagesService.new(project, project.first_owner).execute
    end

    it 'returns repository languages' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:project, :languages)).to eq(expected_languages)
    end
  end
end
