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

  let_it_be(:sub_group) do
    create(:group, parent: group).tap do |g|
      g.add_owner(current_user)
    end
  end

  let_it_be(:template_files) do
    {
      ".gitlab/issue_templates/project_issues_template_a.md" => "project_issues_template_a content",
      ".gitlab/issue_templates/project_issues_template_b.md" => "project_issues_template_b content"
    }
  end

  let_it_be(:project) do
    create(:project, :custom_repo, files: template_files, group: group)
       .tap { |p| group.file_template_project_id = p.id }
  end

  let_it_be(:no_files_project) { create(:project, :custom_repo, group: group) }

  let_it_be(:no_files_project_namespace) { no_files_project.project_namespace }

  let_it_be(:project_namespace) { project.project_namespace }

  let(:expected_graphql_data) { graphql_data['namespace']['workItemDescriptionTemplates']['nodes'] }

  def generate_query(full_path: project_namespace.full_path)
    query = <<~QUERY
      id
      workItemDescriptionTemplates
      {
        nodes {
          category
          name
          content
          projectId
        }
      }
    QUERY

    graphql_query_for('namespace', { 'fullPath' => full_path }, query)
  end

  it 'includes the content, name, category, and project_id fields on each template' do
    post_graphql(generate_query, current_user: current_user)
    expect(template_files.count).to eq(expected_graphql_data.count)

    expected_graphql_data.each_with_index do |template, index|
      expect(".gitlab/issue_templates/#{template['name']}.md").to eq(template_files.to_a[index][0])
      expect(template["content"]).to eq(template_files.to_a[index][1])
      expect(template["category"]).to eq("Project Templates")
      expect(template["projectId"]).to eq(project.id)
    end
  end

  it 'returns nil when the project has no template files' do
    post_graphql(generate_query(full_path: no_files_project_namespace.full_path), current_user: current_user)

    expect(graphql_data["namespace"]["workItemDescriptionTemplates"]).to be_nil
  end

  context 'when the namespace is a Group with no file template project set' do
    before do
      stub_licensed_features(custom_file_templates: true, custom_file_templates_for_namespace: true)
      group.update_columns(file_template_project_id: nil)
    end

    it 'returns nil' do
      post_graphql(generate_query(full_path: group.full_path), current_user: current_user)

      expect(graphql_data["namespace"]["workItemDescriptionTemplates"]).to be_nil
    end
  end
end
