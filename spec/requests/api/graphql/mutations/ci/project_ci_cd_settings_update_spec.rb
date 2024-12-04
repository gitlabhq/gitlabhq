# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ProjectCiCdSettingsUpdate', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) do
    create(:project,
      keep_latest_artifact: true,
      ci_outbound_job_token_scope_enabled: true,
      ci_inbound_job_token_scope_enabled: true
    ).tap(&:save!)
  end

  let(:variables) do
    {
      full_path: project.full_path,
      keep_latest_artifact: false,
      job_token_scope_enabled: false,
      inbound_job_token_scope_enabled: false,
      push_repository_for_job_token_allowed: false
    }
  end

  let(:mutation) { graphql_mutation(:project_ci_cd_settings_update, variables) }

  context 'when unauthorized' do
    let(:user) { create(:user) }

    shared_examples 'unauthorized' do
      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: user)

        expect(graphql_errors).not_to be_empty
      end
    end

    context 'when not a project member' do
      it_behaves_like 'unauthorized'
    end

    context 'when a non-admin project member' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'unauthorized'
    end
  end

  context 'when authorized' do
    let_it_be(:user) { project.first_owner }

    it 'updates ci cd settings' do
      post_graphql_mutation(mutation, current_user: user)

      project.reload

      expect(response).to have_gitlab_http_status(:success)
      expect(project.keep_latest_artifact).to eq(false)
    end

    it 'allows setting job_token_scope_enabled to false' do
      post_graphql_mutation(mutation, current_user: user)

      project.reload

      expect(response).to have_gitlab_http_status(:success)
      expect(project.ci_outbound_job_token_scope_enabled).to eq(false)
    end

    context 'when push_repository_for_job_token_allowed requested to be true' do
      let(:variables) do
        {
          full_path: project.full_path,
          push_repository_for_job_token_allowed: true
        }
      end

      it 'updates push_repository_for_job_token_allowed' do
        post_graphql_mutation(mutation, current_user: user)
        project.reload

        expect(response).to have_gitlab_http_status(:success)
        expect(project.ci_cd_settings.push_repository_for_job_token_allowed).to eq(true)
      end
    end

    context 'when job_token_scope_enabled: true' do
      let(:variables) do
        {
          full_path: project.full_path,
          keep_latest_artifact: false,
          job_token_scope_enabled: true,
          inbound_job_token_scope_enabled: false
        }
      end

      it 'prevents the update', :aggregate_failures do
        project.update!(ci_outbound_job_token_scope_enabled: false)
        post_graphql_mutation(mutation, current_user: user)

        project.reload

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).to(
          include(
            hash_including(
              'message' => 'job_token_scope_enabled can only be set to false'
            )
          )
        )
        expect(project.ci_outbound_job_token_scope_enabled).to eq(false)
      end
    end

    it 'does not update job_token_scope_enabled if not specified' do
      variables.except!(:job_token_scope_enabled)

      post_graphql_mutation(mutation, current_user: user)

      project.reload

      expect(response).to have_gitlab_http_status(:success)
      expect(project.ci_outbound_job_token_scope_enabled).to eq(true)
    end

    describe 'inbound_job_token_scope_enabled' do
      let(:category) { Mutations::Ci::ProjectCiCdSettingsUpdate }

      it 'updates inbound_job_token_scope_enabled' do
        post_graphql_mutation(mutation, current_user: user)

        project.reload

        expect(response).to have_gitlab_http_status(:success)
        expect(project.ci_inbound_job_token_scope_enabled).to eq(false)
      end

      it 'does not update inbound_job_token_scope_enabled if not specified' do
        variables.except!(:inbound_job_token_scope_enabled)

        post_graphql_mutation(mutation, current_user: user)

        project.reload

        expect(response).to have_gitlab_http_status(:success)
        expect(project.ci_inbound_job_token_scope_enabled).to eq(true)
      end

      context 'when inbound_job_token_scope_enabled is changed from false to true' do
        before do
          project.update!(ci_inbound_job_token_scope_enabled: false)
          variables[:inbound_job_token_scope_enabled] = true
        end

        it_behaves_like 'internal event tracking' do
          let(:event) { 'enable_inbound_job_token_scope' }
          subject(:service_action) { post_graphql_mutation(mutation, current_user: user) }
        end
      end

      context 'when inbound_job_token_scope_enabled is changed from true to false' do
        before do
          project.update!(ci_inbound_job_token_scope_enabled: true)
          variables[:inbound_job_token_scope_enabled] = false
        end

        it_behaves_like 'internal event tracking' do
          let(:event) { 'disable_inbound_job_token_scope' }
          subject(:service_action) { post_graphql_mutation(mutation, current_user: user) }
        end
      end

      context 'when inbound_job_token_scope_enabled is true but value is unchanged' do
        subject(:service_action) { post_graphql_mutation(mutation, current_user: user) }

        before do
          project.update!(ci_inbound_job_token_scope_enabled: true)
          variables[:inbound_job_token_scope_enabled] = true
        end

        it 'does not trigger event' do
          expect { service_action }.not_to trigger_internal_events('enable_inbound_job_token_scope')
        end
      end

      context 'when inbound_job_token_scope_enabled is false but value is unchanged' do
        subject(:service_action) { post_graphql_mutation(mutation, current_user: user) }

        before do
          project.update!(ci_inbound_job_token_scope_enabled: false)
          variables[:inbound_job_token_scope_enabled] = false
        end

        it 'does not trigger event' do
          expect { service_action }.not_to trigger_internal_events('disable_inbound_job_token_scope')
        end
      end
    end

    context 'when bad arguments are provided' do
      let(:variables) { { full_path: '', keep_latest_artifact: false } }

      it 'returns the errors' do
        post_graphql_mutation(mutation, current_user: user)

        expect(graphql_errors).not_to be_empty
      end
    end
  end
end
