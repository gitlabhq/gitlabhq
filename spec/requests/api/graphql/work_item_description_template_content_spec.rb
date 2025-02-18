# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a WorkItem description template and content', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) do
    create(:group).tap do |g|
      g.add_owner(current_user)
    end
  end

  let_it_be(:template_files) do
    {
      ".gitlab/issue_templates/project_issues_template_a.md" => "project_issues_template_a content",
      ".gitlab/issue_templates/project_issues_template_b.md" => "project_issues_template_b content"
    }
  end

  let_it_be(:project) { create(:project, :custom_repo, files: template_files, group: group) }

  let(:expected_graphql_data) { graphql_data['workItemDescriptionTemplateContent'] }

  context 'with expected arguments' do
    let(:query) do
      graphql_query_for(:workItemDescriptionTemplateContent,
        { templateContentInput: { projectId: project.id, name: "project_issues_template_a" } })
    end

    it 'returns the expected values for the template being queried' do
      post_graphql(query, current_user: current_user)

      expect(expected_graphql_data["projectId"]).to eq(project.id)
      expect(expected_graphql_data["name"]).to eq("project_issues_template_a")
      expect(expected_graphql_data["category"]).to be_nil
      expect(expected_graphql_data["content"]).to eq("project_issues_template_a content")

      expect(response).to have_gitlab_http_status(:ok)
      expect(graphql_errors).to be_nil
    end
  end

  context 'with a group_id that does not exist' do
    let(:query) do
      graphql_query_for(:workItemDescriptionTemplateContent,
        { templateContentInput: { projectId: -1, name: "project_issues_template_a" } })
    end

    it 'does not retrieve the template' do
      post_graphql(query, current_user: current_user)

      expect(expected_graphql_data).to be_nil
    end
  end

  context 'with a template name that does not exist' do
    let(:query) do
      graphql_query_for(:workItemDescriptionTemplateContent,
        { templateContentInput: { projectId: project.id, name: "missing template" } })
    end

    it 'does not retrieve the template' do
      post_graphql(query, current_user: current_user)

      expect(expected_graphql_data).to be_nil
    end
  end
end
