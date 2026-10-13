# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::PersonalAccessTokensHelpers, feature_category: :system_access do
  let(:helper) { Class.new.include(described_class).new }

  describe '#granular_scopes_options_for' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:legacy_token) { create(:personal_access_token, user: user) }
    let_it_be(:granular_token) do
      create(:granular_pat, user: user, permissions: ['read_job'], boundary: ::Authz::Boundary.for(project))
    end

    # Fresh copies, so that no association the factories built is already loaded.
    let(:legacy) { PersonalAccessToken.find(legacy_token.id) }
    let(:granular) { PersonalAccessToken.find(granular_token.id) }

    subject(:options) { helper.granular_scopes_options_for(tokens) }

    context 'when no token is granular' do
      let(:tokens) { [legacy] }

      it 'returns no options and runs no query', :aggregate_failures do
        tokens

        recorder = ActiveRecord::QueryRecorder.new { options }

        expect(options).to eq({})
        expect(recorder.count).to eq(0)
        expect(legacy.association(:granular_scopes)).not_to be_loaded
      end
    end

    context 'when a token is granular' do
      let(:tokens) { [legacy, granular] }

      it 'returns the options that expose its granular scopes with their project IDs' do
        expect(options).to eq(
          with_granular_scopes: true,
          project_ids_by_namespace_id: { project.project_namespace_id => project.id }
        )
      end

      it 'preloads the granular scopes of the granular token alone, with their namespaces', :aggregate_failures do
        options

        expect(legacy.association(:granular_scopes)).not_to be_loaded
        expect(granular.association(:granular_scopes)).to be_loaded
        expect(granular.granular_scopes.map { |scope| scope.association(:namespace) }).to all(be_loaded)
      end
    end

    context 'when the granular scopes are already loaded' do
      let(:tokens) do
        PersonalAccessToken.id_in([legacy_token.id, granular_token.id]).preload_granular_scopes.to_a
      end

      it 'does not load them again' do
        tokens

        recorder = ActiveRecord::QueryRecorder.new { options }

        expect(recorder.log).not_to include(a_string_matching(/granular_scopes|FROM "namespaces"/))
      end
    end

    # Authn::PersonalAccessTokens::CreateGranularService leaves the token it creates in this state:
    # it reads the scopes back, without their namespaces, to track the creation.
    context 'when the granular scopes are loaded without their namespaces' do
      let_it_be(:other_project) { create(:project) }
      let_it_be(:two_scope_token) do
        create(:granular_pat, user: user, permissions: ['read_job'], boundary: ::Authz::Boundary.for(project),
          additional_scopes: [{ boundary: ::Authz::Boundary.for(other_project), permissions: ['read_job'] }])
      end

      let(:token) { PersonalAccessToken.find(two_scope_token.id) }
      let(:tokens) { [token] }

      before do
        token.granular_scopes.load
      end

      it 'preloads the namespaces of those scopes in one query, without loading the scopes again',
        :aggregate_failures do
        recorder = ActiveRecord::QueryRecorder.new { options }

        expect(recorder.log).not_to include(a_string_matching(/FROM "(personal_access_token_)?granular_scopes"/))
        expect(recorder.log.grep(/FROM "namespaces"/).size).to eq(1)
        expect(options[:project_ids_by_namespace_id]).to eq(
          project.project_namespace_id => project.id,
          other_project.project_namespace_id => other_project.id
        )
      end
    end
  end
end
