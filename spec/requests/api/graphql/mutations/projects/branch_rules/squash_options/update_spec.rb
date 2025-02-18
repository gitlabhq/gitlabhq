# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating a squash option', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:branch_rule) { Projects::AllBranchesRule.new(project) }
  let(:global_id) { branch_rule.to_global_id.to_s }
  let(:mutation) do
    graphql_mutation(:branch_rule_squash_option_update, { branch_rule_id: global_id, squash_option: 'NEVER' })
  end

  let(:mutation_response) { graphql_mutation_response(:branch_rule_squash_option_update) }

  subject(:mutation_request) { post_graphql_mutation(mutation, current_user: current_user) }

  before do
    stub_licensed_features(branch_rule_squash_options: true)
  end

  context 'when the user does not have permission' do
    it_behaves_like 'a mutation that returns top-level errors',
      errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]

    context 'and a squash option exists' do
      let!(:squash_option) { create(:project_setting, project: project) }

      it 'does not update the squash option' do
        expect { mutation_request }.not_to change { squash_option.reload.squash_option }
      end
    end
  end

  context 'when the user has permission' do
    before_all do
      project.add_maintainer(current_user)
    end

    context 'and the branch_rule_squash_settings feature flag is disabled' do
      before do
        stub_feature_flags(branch_rule_squash_settings: false)
      end

      it 'raises an error' do
        mutation_request
        expect(graphql_errors).to include(a_hash_including('message' => 'Squash options feature disabled'))
      end
    end

    it 'updates the squash option' do
      expect do
        mutation_request
      end.to change {
        project.reload.project_setting&.squash_option
      }.from('default_off').to('never')
    end

    it 'responds with the updated squash option' do
      mutation_request

      expect(mutation_response['squashOption']['option']).to eq('Do not allow')
      expect(mutation_response['squashOption']['helpText']).to eq(
        'Squashing is never performed and the checkbox is hidden.'
      )
    end
  end
end
