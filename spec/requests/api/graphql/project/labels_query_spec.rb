# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project label information', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:label_factory) { :label }
  let_it_be(:label_attrs) { { project: project } }

  it_behaves_like 'querying a GraphQL type with labels' do
    let(:path_prefix) { ['project'] }

    def make_query(fields)
      graphql_query_for('project', { full_path: project.full_path }, fields)
    end
  end
end
