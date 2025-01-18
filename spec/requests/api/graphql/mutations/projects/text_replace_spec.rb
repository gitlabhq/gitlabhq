# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projectTextReplace", feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, owner_of: project) }
  let_it_be(:repo) { project.repository }

  let(:project_path) { project.full_path }
  let(:mutation_params) { { project_path: project_path, replacements: replacements } }
  let(:mutation) { graphql_mutation(:project_text_replace, mutation_params) }
  let(:replacements) do
    %w[
      p455w0rd
      foo==>bar
      literal:MM/DD/YYYY==>YYYY-MM-DD
    ]
  end

  let(:literal_replacements) do
    %w[
      literal:p455w0rd
      literal:foo==>bar
      literal:MM/DD/YYYY==>YYYY-MM-DD
    ]
  end

  subject(:post_mutation) { post_graphql_mutation(mutation, current_user: current_user) }

  describe 'Replacing text' do
    it 'processes text redaction asynchoronously' do
      expect(::Repositories::RewriteHistoryWorker).to receive(:perform_async).with(
        project_id: project.id, user_id: current_user.id, redactions: literal_replacements, blob_oids: []
      )

      post_mutation

      expect(graphql_mutation_response(:project_text_replace)['errors']).not_to be_present
    end
  end

  describe 'Invalid requests:' do
    context 'when the current_user is a maintainer' do
      let(:current_user) { create(:user, maintainer_of: project) }

      it_behaves_like 'a mutation on an unauthorized resource'
    end

    context 'when arg `projectPath` is invalid' do
      let(:project_path) { 'gid://Gitlab/User/1' }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => <<~MESSAGE.strip))
          The resource that you are attempting to access does not exist or you don't have permission to perform this action
        MESSAGE
      end
    end

    context 'when arg `replacements` is nil' do
      let(:replacements) { nil }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => <<~MESSAGE.strip))
          Variable $projectTextReplaceInput of type projectTextReplaceInput! was provided invalid value for replacements (Expected value to not be null)
        MESSAGE
      end
    end

    context 'when arg `replacements` is an empty list' do
      let(:replacements) { [] }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => <<~MESSAGE))
          Argument 'replacements' on InputObject 'projectTextReplaceInput' is required. Expected type [String!]!
        MESSAGE
      end
    end

    context 'when arg `replacements` does not contain any valid strings' do
      let(:replacements) { ["", ""] }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => <<~MESSAGE))
          Argument 'replacements' on InputObject 'projectTextReplaceInput' is required. Expected type [String!]!
        MESSAGE
      end
    end

    context 'when arg `replacements` includes a regex' do
      let(:replacements) { ['regex:\bdriver\b==>pilot'] }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => <<~MESSAGE))
          Argument 'replacements' on InputObject 'projectTextReplaceInput' does not support 'regex:' or 'glob:' values.
        MESSAGE
      end
    end

    context 'when arg `replacements` includes a glob' do
      let(:replacements) { ['glob:**string**==>'] }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(a_hash_including('message' => <<~MESSAGE))
          Argument 'replacements' on InputObject 'projectTextReplaceInput' does not support 'regex:' or 'glob:' values.
        MESSAGE
      end
    end
  end
end
