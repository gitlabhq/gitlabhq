# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectsController, :with_license, feature_category: :groups_and_projects do
  context 'token authentication' do
    context 'when public project' do
      let_it_be(:public_project) { create(:project, :public) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'show atom', public_resource: true do
        let(:url) { project_url(public_project, format: :atom) }
      end
    end

    context 'when private project' do
      let_it_be(:private_project) { create(:project, :private) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'show atom', public_resource: false, ignore_metrics: true do
        let(:url) { project_url(private_project, format: :atom) }

        before do
          private_project.add_maintainer(user)
        end
      end
    end
  end

  describe 'GET #show' do
    context 'step-up authentication enforcement' do
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be(:user, reload: true) { create(:user, developer_of: group) }
      let(:expected_success_status) { :ok }

      subject(:make_request) { get project_path(project) }

      context 'for private project' do
        let_it_be(:project, freeze: true) { create(:project, :private, namespace: group) }

        context 'when user authenticated' do
          before do
            sign_in(user)
          end

          it_behaves_like 'enforces step-up authentication (request spec)'
        end
      end

      context 'for public project', quarantine: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/18621' do
        let_it_be(:project, freeze: true) { create(:project, :public, namespace: group) }

        context 'when user authenticated' do
          before do
            sign_in(user)
          end

          it_behaves_like 'enforces step-up authentication (request spec)'
        end

        context 'when user unauthenticated' do
          it_behaves_like 'does not enforce step-up authentication'
        end
      end
    end
  end

  describe 'GET #edit' do
    context 'step-up authentication enforcement' do
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be(:project, freeze: true) { create(:project, namespace: group) }

      subject(:make_request) { get edit_project_path(project) }

      before do
        sign_in(user)
      end

      context 'when user is maintainer' do
        let_it_be(:user, reload: true) { create(:user, maintainer_of: project) }
        let(:expected_success_status) { :ok }

        it_behaves_like 'enforces step-up authentication (request spec)'
      end

      context 'when user is developer' do
        let_it_be(:user, reload: true) { create(:user, developer_of: project) }
        let(:expected_success_status) { :not_found }

        it_behaves_like 'does not enforce step-up authentication'
      end

      context 'when user is not a member' do
        let_it_be(:user, reload: true) { create(:user) }
        let(:expected_success_status) { :not_found }

        it_behaves_like 'does not enforce step-up authentication'
      end
    end
  end

  context 'GET #new' do
    let_it_be_with_reload(:group) { create(:group) }
    let_it_be_with_reload(:user) { create(:user, :with_namespace, owner_of: group) }
    let(:expected_success_status) { :ok }

    subject(:make_request) { get new_project_path(namespace_id: group.id) }

    before do
      sign_in(user)
    end

    it_behaves_like 'enforces step-up authentication (request spec)'

    context 'with invalid namespace_id' do
      subject(:make_request) { get new_project_path(namespace_id: non_existing_record_id) }

      it 'returns 404 when namespace does not exist' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'POST #create' do
    let_it_be_with_reload(:group) { create(:group) }
    let_it_be_with_reload(:user) { create(:user, :with_namespace, owner_of: group) }
    let(:expected_success_status) { :found }

    let(:project_params) do
      {
        name: 'Test Project',
        path: 'test-project',
        namespace_id: group.id,
        visibility_level: Gitlab::VisibilityLevel::PRIVATE
      }
    end

    subject(:make_request) { post projects_path, params: { project: project_params } }

    before do
      sign_in(user)
    end

    it_behaves_like 'enforces step-up authentication (request spec)'

    context 'with invalid namespace_id' do
      let(:project_params) do
        {
          name: 'Test Project',
          path: 'test-project',
          namespace_id: non_existing_record_id,
          visibility_level: Gitlab::VisibilityLevel::PRIVATE
        }
      end

      it 'returns 404 when trying to create project with non-existent namespace' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PUT #transfer' do
    context 'when namespace does not exist' do
      let_it_be(:user) { create(:user) }
      let_it_be_with_reload(:project) { create(:project) }

      before_all do
        project.add_owner(user)
      end

      before do
        sign_in(user)
      end

      it 'redirects with an error without enqueuing a worker' do
        expect(Projects::TransferWorker).not_to receive(:perform_async)

        put transfer_project_path(project), params: { new_namespace_id: non_existing_record_id }

        expect(response).to redirect_to(edit_project_path(project))
        expect(flash[:alert]).to eq('Please select a new namespace for your project.')
      end
    end

    context 'when groups_and_projects_async_transfer feature flag is enabled' do
      let_it_be(:user) { create(:user) }
      let_it_be_with_reload(:project) { create(:project) }
      let_it_be(:new_namespace) { create(:group) }

      before_all do
        project.add_owner(user)
        new_namespace.add_owner(user)
      end

      before do
        sign_in(user)
      end

      it 'enqueues the async transfer worker' do
        expect(Projects::TransferWorker).to receive(:perform_async).with(
          project.id,
          new_namespace.id,
          user.id
        )

        put transfer_project_path(project), params: { new_namespace_id: new_namespace.id }

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(edit_project_path(project))
      end

      it 'transitions the project namespace to transfer_scheduled and stores metadata' do
        put transfer_project_path(project), params: { new_namespace_id: new_namespace.id }

        project_namespace = project.project_namespace.reload
        expect(project_namespace.state).to eq('transfer_scheduled')
        expect(project_namespace.state_metadata['transfer_target_parent_id']).to eq(new_namespace.id)
      end

      context 'when the state transition fails' do
        before do
          project.project_namespace.update_column(:state, Namespace.states[:creation_in_progress])
        end

        it 'does not enqueue the worker and redirects with an error' do
          expect(Projects::TransferWorker).not_to receive(:perform_async)

          put transfer_project_path(project), params: { new_namespace_id: new_namespace.id }

          expect(response).to redirect_to(edit_project_path(project))
          expect(flash[:alert]).to eq('Unable to initiate transfer. The project may already have a transfer in progress.')
        end
      end
    end

    context 'when groups_and_projects_async_transfer feature flag is disabled' do
      let_it_be(:user) { create(:user) }
      let_it_be_with_reload(:project) { create(:project) }
      let_it_be(:new_namespace) { create(:group) }

      before_all do
        project.add_owner(user)
        new_namespace.add_owner(user)
      end

      before do
        stub_feature_flags(groups_and_projects_async_transfer: false)
        sign_in(user)
      end

      it 'transfers the project synchronously' do
        expect(Projects::TransferWorker).not_to receive(:perform_async)

        put transfer_project_path(project), params: { new_namespace_id: new_namespace.id }

        expect(response).to have_gitlab_http_status(:found)
        expect(project.reload.namespace).to eq(new_namespace)
      end

      context 'when the transfer fails' do
        it 'redirects with an error' do
          put transfer_project_path(project), params: { new_namespace_id: project.namespace_id }

          expect(response).to redirect_to(edit_project_path(project))
          expect(flash[:alert]).to include('Project is already in this namespace')
        end
      end
    end
  end
end
