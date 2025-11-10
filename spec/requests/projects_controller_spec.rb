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

          it_behaves_like 'enforces step-up authentication'
        end
      end

      context 'for public project' do
        let_it_be(:project, freeze: true) { create(:project, :public, namespace: group) }

        context 'when user authenticated' do
          before do
            sign_in(user)
          end

          it_behaves_like 'enforces step-up authentication'
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

        it_behaves_like 'enforces step-up authentication'
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

    it_behaves_like 'enforces step-up authentication'

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

    it_behaves_like 'enforces step-up authentication'

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
end
