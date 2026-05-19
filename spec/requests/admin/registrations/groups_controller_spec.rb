# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Registrations::GroupsController, feature_category: :onboarding do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:regular_user) { create(:user) }

  describe 'GET /admin/registrations/groups/new' do
    subject(:get_new) { get new_admin_registrations_group_path }

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(self_managed_welcome_onboarding: false)
        sign_in(admin)
      end

      it 'returns not found', :enable_admin_mode do
        get_new

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when on a Dedicated instance' do
      before do
        stub_application_setting(gitlab_dedicated_instance: true)
        sign_in(admin)
      end

      it 'returns not found', :enable_admin_mode do
        get_new

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the feature flag is enabled' do
      context 'with an unauthenticated user' do
        it 'redirects to sign in' do
          get_new

          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'with a non-admin user' do
        before do
          sign_in(regular_user)
        end

        it 'returns not found' do
          get_new

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when admin mode is not enabled' do
        before do
          sign_in(admin)
        end

        it 'redirects to admin mode login' do
          get_new

          expect(response).to redirect_to(new_admin_session_path)
        end
      end

      context 'with an admin user', :enable_admin_mode do
        before do
          sign_in(admin)
        end

        it 'returns ok' do
          get_new

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'tracks the view event' do
          expect { get_new }
            .to trigger_internal_events('view_create_first_project_page')
            .with(user: admin, additional_properties: {})
        end
      end
    end
  end

  describe 'POST /admin/registrations/groups' do
    let(:group_params) do
      { name: 'My Group', path: 'my-group' }
    end

    let(:project_params) do
      { name: 'My Project', path: 'my-project' }
    end

    subject(:post_create) do
      post admin_registrations_groups_path, params: { group: group_params, project: project_params }
    end

    context 'with an authenticated admin user', :enable_admin_mode do
      before do
        sign_in(admin)
      end

      context 'with valid params' do
        before do
          # Group + project creation exceeds the default 100-query limit.
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/583774
          allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(135)
        end

        it 'creates a group and project' do
          expect { post_create }.to change { Group.count }.by(1).and change { Project.count }.by(1)
        end

        it 'tracks the submit event with success label' do
          expect { post_create }
            .to trigger_internal_events('submit_create_first_project_form')
            .with(user: admin, additional_properties: { label: 'success' })
        end

        context 'when project_template_name is provided' do
          subject(:post_create_with_template) do
            post admin_registrations_groups_path,
              params: { group: group_params, project: project_params.merge(project_template_name: 'rails') }
          end

          it 'passes template_name to the service' do
            service = instance_double(Onboarding::SelfManaged::StandardNamespaceCreateService)
            allow(service).to receive(:execute)
              .and_return(ServiceResponse.success(payload: { project: build_stubbed(:project) }))
            expect(Onboarding::SelfManaged::StandardNamespaceCreateService).to receive(:new).with(
              admin,
              hash_including(project_params: hash_including(template_name: 'rails'))
            ).and_return(service)

            post_create_with_template
          end
        end

        context 'when project_template_name is blank' do
          subject(:post_create_no_template) do
            post admin_registrations_groups_path,
              params: { group: group_params, project: project_params.merge(project_template_name: '') }
          end

          it 'passes template_name as nil to the service' do
            service = instance_double(Onboarding::SelfManaged::StandardNamespaceCreateService)
            allow(service).to receive(:execute)
              .and_return(ServiceResponse.success(payload: { project: build_stubbed(:project) }))
            expect(Onboarding::SelfManaged::StandardNamespaceCreateService).to receive(:new).with(
              admin,
              hash_including(project_params: hash_including(template_name: nil))
            ).and_return(service)

            post_create_no_template
          end
        end

        context 'when template availability changes between requests (license change simulation)' do
          let(:fake_template) { instance_double(Gitlab::ProjectTemplate, name: 'new_enterprise_template') }

          it 'reflects the updated template list on each request without an app restart' do
            # First request: template not yet available (license not yet applied)
            allow(Gitlab::ProjectTemplate).to receive(:all).and_return([])
            service1 = instance_double(Onboarding::SelfManaged::StandardNamespaceCreateService)
            allow(service1).to receive(:execute)
              .and_return(ServiceResponse.success(payload: { project: build_stubbed(:project) }))
            expect(Onboarding::SelfManaged::StandardNamespaceCreateService).to receive(:new).with(
              admin,
              hash_including(project_params: hash_including(template_name: nil))
            ).and_return(service1)

            post admin_registrations_groups_path,
              params: { group: group_params,
                        project: project_params.merge(project_template_name: 'new_enterprise_template') }

            # Second request: license updated, template now valid
            allow(Gitlab::ProjectTemplate).to receive(:all).and_return([fake_template])
            service2 = instance_double(Onboarding::SelfManaged::StandardNamespaceCreateService)
            allow(service2).to receive(:execute)
              .and_return(ServiceResponse.success(payload: { project: build_stubbed(:project) }))
            expect(Onboarding::SelfManaged::StandardNamespaceCreateService).to receive(:new).with(
              admin,
              hash_including(project_params: hash_including(template_name: 'new_enterprise_template'))
            ).and_return(service2)

            post admin_registrations_groups_path,
              params: { group: group_params,
                        project: project_params.merge(project_template_name: 'new_enterprise_template') }
          end
        end

        it 'redirects to the profile step' do
          post_create

          expect(response).to redirect_to(new_admin_registrations_profile_path)
        end

        it 'stores the created project id in the session' do
          post_create

          expect(session[:sm_welcome_project_id]).to eq(Project.last.id)
        end

        it 'creates the group as PRIVATE regardless of params' do
          public_group_params = group_params.merge(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          post admin_registrations_groups_path,
            params: { group: public_group_params, project: project_params }

          expect(Group.last.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
        end

        it 'sets group organization_id from Current.organization, not from params' do
          org = create(:organization)
          allow(Current).to receive(:organization).and_return(org)

          post admin_registrations_groups_path,
            params: { group: group_params.merge(organization_id: 99999), project: project_params }

          expect(Group.last.organization_id).to eq(org.id)
        end

        it 'sets project organization_id from Current.organization, not from params' do
          org = create(:organization)
          allow(Current).to receive(:organization).and_return(org)

          post admin_registrations_groups_path,
            params: { group: group_params, project: project_params.merge(organization_id: 99999) }

          expect(Project.last.organization_id).to eq(org.id)
        end
      end

      context 'when the group cannot be created' do
        let(:group_params) { { name: '', path: '' } }

        it 'does not create a group or project' do
          expect { post_create }
            .to not_change { Group.count }
            .and not_change { Project.count }
        end

        it 're-renders the form with unprocessable_entity status' do
          post_create

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(response.body).to include('Create your first project')
        end

        it 'does not track the view event on re-render' do
          expect { post_create }.not_to trigger_internal_events('view_create_first_project_page')
        end

        it 'tracks the submit event with failure label' do
          expect { post_create }
            .to trigger_internal_events('submit_create_first_project_form')
            .with(user: admin, additional_properties: { label: 'failure' })
        end
      end

      context 'when the project cannot be created' do
        let(:project_params) { { name: '', path: '' } }

        it 'creates the group but not the project' do
          expect { post_create }
            .to change { Group.count }.by(1)
            .and not_change { Project.count }
        end

        it 're-renders the form with unprocessable_entity status' do
          post_create

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end

        it 'does not track the view event on re-render' do
          expect { post_create }.not_to trigger_internal_events('view_create_first_project_page')
        end

        it 'tracks the submit event with failure label' do
          expect { post_create }
            .to trigger_internal_events('submit_create_first_project_form')
            .with(user: admin, additional_properties: { label: 'failure' })
        end
      end

      context 'when :self_managed_welcome_onboarding is disabled' do
        before do
          stub_feature_flags(self_managed_welcome_onboarding: false)
        end

        it 'returns 404' do
          post_create

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with a non-admin user' do
      before do
        sign_in(regular_user)
      end

      it 'returns 404' do
        post_create

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with an unauthenticated user' do
      it 'redirects to sign in' do
        post_create

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
