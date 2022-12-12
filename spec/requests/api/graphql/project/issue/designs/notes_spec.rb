# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting designs related to an issue', feature_category: :design_management do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:design) { create(:design, :with_file, versions_count: 1, issue: issue) }
  let_it_be(:current_user) { project.first_owner }
  let_it_be(:note) { create(:diff_note_on_design, noteable: design, project: project) }

  before do
    enable_design_management
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  it_behaves_like 'a noteable graphql type we can query' do
    let(:noteable) { design }
    let(:note_factory) { :diff_note_on_design }
    let(:discussion_factory) { :diff_note_on_design }
    let(:path_to_noteable) { [:issue, :design_collection, :designs, :nodes, 0] }

    before do
      project.add_developer(current_user)
    end

    def query(fields)
      graphql_query_for(:issue, { id: global_id_of(issue) }, <<~FIELDS)
        designCollection { designs { nodes { #{fields} } } }
      FIELDS
    end
  end

  it 'is not too deep for anonymous users' do
    note_fields = <<~FIELDS
      id
      author { name }
    FIELDS

    post_graphql(query(note_fields), current_user: nil)

    designs_data = graphql_data['project']['issue']['designCollection']['designs']
    design_data = designs_data['nodes'].first
    note_data = design_data['notes']['nodes'].first

    expect(note_data).to match(a_graphql_entity_for(note))
  end

  def query(note_fields = all_graphql_fields_for(Note, max_depth: 1))
    design_node = <<~NODE
    designs {
      nodes {
        notes {
          nodes {
            #{note_fields}
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
          'designCollection', {}, design_node
        )
      )
    )
  end
end
