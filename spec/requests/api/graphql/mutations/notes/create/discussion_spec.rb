# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Adding an DiscussionNote', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:noteable) { create(:merge_request, source_project: project, target_project: project) }
  let(:project) { create(:project, :repository) }
  let(:diff_refs) { noteable.diff_refs }
  let(:mutation) do
    variables = {
      noteable_id: GitlabSchema.id_from_object(noteable).to_s,
      body: 'Body text'
    }

    graphql_mutation(:create_discussion, variables)
  end

  def mutation_response
    graphql_mutation_response(:create_discussion)
  end

  it_behaves_like 'a Note mutation when the user does not have permission'

  context 'when the user has permission' do
    before do
      project.add_developer(current_user)
    end

    it_behaves_like 'a Note mutation that creates a Note'

    it_behaves_like 'a Note mutation when there are active record validation errors', model: DiscussionNote

    it_behaves_like 'a Note mutation when there are rate limit validation errors'

    it 'returns the discussion' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['note']['body']).to eq('Body text')
    end
  end
end
