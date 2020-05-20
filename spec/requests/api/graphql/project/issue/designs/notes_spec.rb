# frozen_string_literal: true

require 'spec_helper'

describe 'Getting designs related to an issue' do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:design) { create(:design, :with_file, versions_count: 1, issue: issue) }
  let_it_be(:current_user) { project.owner }
  let_it_be(:note) { create(:diff_note_on_design, noteable: design, project: project) }

  before do
    enable_design_management

    note
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  it 'is not too deep for anonymous users' do
    note_fields = <<~FIELDS
      id
      author { name }
    FIELDS

    post_graphql(query(note_fields), current_user: nil)

    designs_data = graphql_data['project']['issue']['designs']['designs']
    design_data = designs_data['edges'].first['node']
    note_data = design_data['notes']['edges'].first['node']

    expect(note_data['id']).to eq(note.to_global_id.to_s)
  end

  def query(note_fields = all_graphql_fields_for(Note))
    design_node = <<~NODE
    designs {
      edges {
        node {
          notes {
            edges {
              node {
                #{note_fields}
              }
            }
          }
        }
      }
    }
    NODE
    graphql_query_for(
      'project',
      { 'fullPath' => design.project.full_path },
      query_graphql_field(
        'issue',
        { iid: design.issue.iid.to_s },
        query_graphql_field(
          'designs', {}, design_node
        )
      )
    )
  end
end
