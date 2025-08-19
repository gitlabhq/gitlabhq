# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ProjectCiCdSettingsUpdate', feature_category: :continuous_integration do
  include GraphqlHelpers

  def response_errors
    (graphql_errors || []) + (graphql_data_at('projectCiCdSettingsUpdate', 'errors') || [])
  end

  let_it_be_with_reload(:project) do
    create(:project,
      group_runners_enabled: true,
      keep_latest_artifact: true,
      ci_outbound_job_token_scope_enabled: true,
      ci_inbound_job_token_scope_enabled: true
    ).tap(&:save!)
  end

  let(:variables) do
    {
      full_path: project.full_path,
      group_runners_enabled: false,
      keep_latest_artifact: false,
      job_token_scope_enabled: false,
      inbound_job_token_scope_enabled: false,
      push_repository_for_job_token_allowed: false,
      pipeline_variables_minimum_override_role: 'no_one_allowed'
    }
  end

  let(:mutation) { graphql_mutation(:project_ci_cd_settings_update, variables) }

  context 'when unauthorized' do
    let_it_be(:user) { create(:user) }

    shared_examples 'unauthorized' do
      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response_errors).not_to be_empty
      end
    end

    context 'when not a project member' do
      it_behaves_like 'unauthorized'
    end

    context 'when a non-admin project member' do
      before_all do
        project.add_developer(user)
      end

      it_behaves_like 'unauthorized'
    end
  end

  context 'when authorized' do
    let_it_be(:user) { project.first_owner }

    it 'updates ci cd settings', :aggregate_failures do
      post_graphql_mutation(mutation, current_user: user)

      project.reload

      expect(response).to have_gitlab_http_status(:success)
      expect(response_errors).to be_blank
      expect(project.group_runners_enabled).to be(false)
      expect(project.keep_latest_artifact).to be(false)
      expect(project.restrict_user_defined_variables?).to be(true)
      expect(project.ci_pipeline_variables_minimum_override_role).to eq('no_one_allowed')
    end

    it 'allows setting job_token_scope_enabled to false' do
      post_graphql_mutation(mutation, current_user: user)

      project.reload

      expect(response).to have_gitlab_http_status(:success)
      expect(response_errors).to be_blank
      expect(project.ci_outbound_job_token_scope_enabled).to be(false)
    end

    context 'when push_repository_for_job_token_allowed requested to be true' do
      let(:variables) do
        {
          full_path: project.full_path,
          push_repository_for_job_token_allowed: true
        }
      end

      it 'updates push_repository_for_job_token_allowed', :aggregate_failures do
        post_graphql_mutation(mutation, current_user: user)
        project.reload

        expect(response).to have_gitlab_http_status(:success)
        expect(response_errors).to be_blank
        expect(project.ci_cd_settings.push_repository_for_job_token_allowed).to be(true)
      end
    end

    context 'when display_pipeline_variables is updated' do
      let(:variables) do
        {
          full_path: project.full_path,
          display_pipeline_variables: true
        }
      end

      it 'updates the setting' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(project.reload.ci_cd_settings.display_pipeline_variables).to be(true)
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
        expect(response_errors).to(
          include(
            hash_including(
              'message' => 'job_token_scope_enabled can only be set to false'
            )
          )
        )
        expect(project.ci_outbound_job_token_scope_enabled).to be(false)
      end
    end

    it 'does not update job_token_scope_enabled if not specified', :aggregate_failures do
      variables.except!(:job_token_scope_enabled)

      post_graphql_mutation(mutation, current_user: user)

      project.reload

      expect(response).to have_gitlab_http_status(:success)
      expect(project.ci_outbound_job_token_scope_enabled).to be(true)
    end

    describe 'inbound_job_token_scope_enabled' do
      it 'updates inbound_job_token_scope_enabled', :aggregate_failures do
        post_graphql_mutation(mutation, current_user: user)

        project.reload

        expect(response).to have_gitlab_http_status(:success)
        expect(response_errors).to be_blank
        expect(project.ci_inbound_job_token_scope_enabled).to be(false)
      end

      it 'does not update inbound_job_token_scope_enabled if not specified', :aggregate_failures do
        variables.except!(:inbound_job_token_scope_enabled)

        post_graphql_mutation(mutation, current_user: user)

        project.reload

        expect(response).to have_gitlab_http_status(:success)
        expect(response_errors).to be_blank
        expect(project.ci_inbound_job_token_scope_enabled).to be(true)
      end

      context 'when inbound_job_token_scope_enabled is changed from false to true' do
        before do
          project.update!(ci_inbound_job_token_scope_enabled: false)
          variables[:inbound_job_token_scope_enabled] = true
        end

        it_behaves_like 'internal event tracking' do
          let(:category) { Projects::UpdateService }
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
          let(:category) { Projects::UpdateService }
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

    describe 'pipeline_variables_minimum_override_role' do
      let_it_be(:owner) { user }
      let_it_be(:maintainer) { create(:user, maintainer_of: project) }
      let(:initial_restrict_user_defined_variables) { false }

      let(:variables) do
        {
          full_path: project.full_path,
          pipeline_variables_minimum_override_role: 'maintainer'
        }
      end

      before do
        override_role = initial_restrict_user_defined_variables ? 'no_one_allowed' : 'developer'
        project.ci_cd_settings.update!(
          pipeline_variables_minimum_override_role: override_role
        )
      end

      specify do
        expect { post_graphql_mutation(mutation, current_user: maintainer) }.to(
          change { project.reload.restrict_user_defined_variables? }
            .from(false)
            .to(true)
        )
      end

      context 'when pipeline_variables_minimum_override_role is not specified' do
        using RSpec::Parameterized::TableSyntax

        let(:variables) do
          {
            full_path: project.full_path,
            push_repository_for_job_token_allowed: true
          }
        end

        where(:initial_restrict_user_defined_variables) { [false, true] }

        with_them do
          specify do
            expect { post_graphql_mutation(mutation, current_user: maintainer) }.not_to(
              change { project.reload.restrict_user_defined_variables? }
                .from(initial_restrict_user_defined_variables)
            )
          end
        end
      end

      it 'maintainers can change minimum override role to a non-owner value', :aggregate_failures do
        expect { post_graphql_mutation(mutation, current_user: maintainer) }.to(
          change { project.reload.ci_pipeline_variables_minimum_override_role }
            .from('developer')
            .to('maintainer')
        )

        expect(response_errors).to be_blank
        expect(response).to have_gitlab_http_status(:success)
      end

      context 'when changing to owner' do
        let(:variables) do
          {
            full_path: project.full_path,
            pipeline_variables_minimum_override_role: 'owner'
          }
        end

        it 'is allowed for owners', :aggregate_failures do
          expect { post_graphql_mutation(mutation, current_user: owner) }.to(
            change { project.reload.ci_pipeline_variables_minimum_override_role }
              .from('developer')
              .to('owner')
          )

          expect(response_errors).to be_blank
          expect(response).to have_gitlab_http_status(:success)
        end

        it 'is not allowed for maintainers', :aggregate_failures do
          expect { post_graphql_mutation(mutation, current_user: maintainer) }.not_to(
            change { project.reload.ci_pipeline_variables_minimum_override_role }
          )

          expect(response_errors).to(
            include(
              'Changing the ci_pipeline_variables_minimum_override_role to the owner role is not allowed'
            )
          )

          expect(response).to have_gitlab_http_status(:success)
        end
      end
    end

    context 'when bad arguments are provided' do
      let(:variables) { { full_path: '', keep_latest_artifact: false } }

      it 'returns the errors' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response_errors).to be_present
      end
    end
  end
end
