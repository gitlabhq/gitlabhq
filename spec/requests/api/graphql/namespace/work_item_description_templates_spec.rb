# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting work item description templates', feature_category: :groups_and_projects do
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
  let_it_be(:project_namespace) { project.project_namespace }

  let(:expected_graphql_data) { graphql_data['namespace']['workItemDescriptionTemplates']['nodes'] }

  def generate_query(name: nil, full_path: project_namespace.full_path)
    query = <<~QUERY
      id
      workItemDescriptionTemplates
      {
        nodes {
          name
          content
        }
      }
    QUERY

    # Add the `name` argument conditionally to query string if it's provided
    query = query.sub("workItemDescriptionTemplates", "workItemDescriptionTemplates(name: \"#{name}\")") if name

    graphql_query_for('namespace', { 'fullPath' => full_path }, query)
  end

  it 'includes the content and name fields on each template' do
    post_graphql(generate_query, current_user: current_user)
    expect(template_files.count).to eq(expected_graphql_data.count)

    expected_graphql_data.each_with_index do |template, index|
      expect(".gitlab/issue_templates/#{template['name']}.md").to eq(template_files.to_a[index][0])
      expect(template["content"]).to eq(template_files.to_a[index][1])
    end
  end

  context 'when filtering by template name that exists' do
    it 'returns matching template' do
      post_graphql(generate_query(name: "project_issues_template_a"), current_user: current_user)

      expect(expected_graphql_data.count).to eq(1)

      expect(expected_graphql_data.first["name"]).to eq("project_issues_template_a")

      expect(expected_graphql_data.first["content"]).to eq("project_issues_template_a content")
    end
  end

  context 'when filtering by a name that does not exist' do
    it 'returns no templates' do
      post_graphql(generate_query(name: "false_name"), current_user: current_user)

      expect(expected_graphql_data).to be_empty
    end
  end

  context 'when the user has access to the namespace but not the project' do
    it 'returns no templates' do
      group.update_columns(file_template_project_id: project.id)

      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(current_user, :read_project, project).and_return(false)

      post_graphql(generate_query(name: nil, full_path: group.full_path), current_user: current_user)

      expect(expected_graphql_data).to be_empty
    end
  end
end
