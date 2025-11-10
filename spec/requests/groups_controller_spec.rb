# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsController, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  context 'token authentication' do
    context 'when public group' do
      let_it_be(:public_group) { create(:group, :public) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'show atom', public_resource: true do
        let(:url) { group_path(public_group, format: :atom) }
      end

      it_behaves_like 'authenticates sessionless user for the request spec', 'issues atom', public_resource: true do
        let(:url) { issues_group_path(public_group, format: :atom) }
      end

      it_behaves_like 'authenticates sessionless user for the request spec', 'issues_calendar ics', public_resource: true do
        let(:url) { issues_group_calendar_url(public_group, format: :ics) }
      end
    end

    context 'when private group' do
      let_it_be(:private_group) { create(:group, :private) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'show atom', public_resource: false, ignore_metrics: true do
        let(:url) { group_path(private_group, format: :atom) }

        before do
          private_group.add_maintainer(user)
        end
      end

      it_behaves_like 'authenticates sessionless user for the request spec', 'issues atom', public_resource: false, ignore_metrics: true do
        let(:url) { issues_group_path(private_group, format: :atom) }

        before do
          private_group.add_maintainer(user)
        end
      end

      it_behaves_like 'authenticates sessionless user for the request spec', 'issues_calendar ics', public_resource: false, ignore_metrics: true do
        let(:url) { issues_group_calendar_url(private_group, format: :ics) }

        before do
          private_group.add_maintainer(user)
        end
      end
    end
  end

  describe 'POST #preview_markdown' do
    let_it_be(:group) { create(:group) }
    let_it_be(:developer) { create(:user, developer_of: group) }

    before do
      login_as(developer)
    end

    context 'when type is WorkItem' do
      let(:url) { group_preview_markdown_url(group, target_type: 'WorkItem', target_id: work_item.iid) }

      context 'when work item exists at the group level' do
        let(:work_item) { create(:work_item, :group_level, namespace: group) }

        it 'returns the markdown preview HTML', :aggregate_failures do
          post url, params: { text: '## Test markdown preview' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['body']).to include('Test markdown preview')
        end
      end
    end
  end

  describe 'GET #index' do
    context 'step-up authentication enforcement' do
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be(:user, reload: true) { create(:user, owner_of: group) }
      let(:expected_success_status) { :found }

      subject(:make_request) { get groups_path }

      before do
        sign_in(user)
      end

      it_behaves_like 'does not enforce step-up authentication'
    end
  end

  describe 'GET #show' do
    context 'when group path contains format extensions' do
      where(:extension) { %w[.html .json] }

      with_them do
        let(:path) { 'my-group' }
        let(:group) { create(:group, path: "#{path}#{extension}") }
        let(:url) { group_path(group) }

        it 'resolves the group correctly' do
          get url

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:group)).to eq(group)
          expect(response).to render_template('groups/show')
        end

        it 'does not treat extension as format parameter' do
          get url

          expect(controller.params[:id]).to eq(group.to_param)
        end

        it 'does not resolve to the group without the extension' do
          create(:group, path: path) # group without the extension

          get url

          expect(assigns(:group)).to eq(group)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'step-up authentication enforcement' do
      let(:expected_success_status) { :ok }

      subject(:make_request) { get group_path(group) }

      context 'for private group' do
        let_it_be(:group, reload: true) { create(:group, :private) }
        let_it_be(:user, reload: true) { create(:user, owner_of: group) }

        context 'when user authenticated' do
          before do
            sign_in(user)
          end

          it_behaves_like 'enforces step-up authentication'
        end
      end

      context 'for public group' do
        let_it_be(:group, reload: true) { create(:group) }
        let_it_be(:user, reload: true) { create(:user, owner_of: group) }

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

  describe 'GET #new' do
    context 'step-up authentication enforcement' do
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be(:user, reload: true) { create(:user, owner_of: group) }
      let(:expected_success_status) { :ok }

      subject(:make_request) { get new_group_path }

      before do
        sign_in(user)
      end

      it_behaves_like 'does not enforce step-up authentication'
    end
  end

  describe 'POST #create' do
    context 'step-up authentication enforcement' do
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be(:user, reload: true) { create(:user, owner_of: group) }
      let(:expected_success_status) { :found }

      subject(:make_request) do
        post groups_path, params: { group: { name: 'New Group', path: 'new-group' } }
      end

      before do
        sign_in(user)
      end

      it_behaves_like 'does not enforce step-up authentication'
    end
  end

  describe 'GET #edit' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:owner) { create(:user) }
    let_it_be(:maintainer) { create(:user) }
    let(:url) { edit_group_path(group) }

    before_all do
      group.add_owner(owner)
      group.add_maintainer(maintainer)
    end

    context 'when the group is archived' do
      before do
        group.namespace_settings.update!(archived: true)
      end

      context 'when user is owner' do
        before do
          login_as(owner)
        end

        it 'allows access to edit page' do
          get url

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when user is maintainer' do
        before do
          login_as(maintainer)
        end

        it 'returns a 404' do
          get url

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when the group is unarchived' do
      before do
        group.namespace_settings.update!(archived: false)
      end

      context 'when user is owner' do
        before do
          login_as(owner)
        end

        it 'allows access to edit page' do
          get url

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when user is maintainer' do
        before do
          login_as(maintainer)
        end

        it 'returns a 404' do
          get url

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'step-up authentication enforcement' do
      let_it_be(:group, reload: true) { create(:group) }

      subject(:make_request) { get edit_group_path(group) }

      before do
        sign_in(user)
      end

      context 'when user is owner' do
        let_it_be_with_reload(:user) { create(:user, owner_of: group) }

        let(:expected_success_status) { :ok }

        it_behaves_like 'does not enforce step-up authentication'
      end

      context 'when user is maintainer' do
        let_it_be_with_reload(:user) { create(:user, maintainer_of: group) }

        let(:expected_success_status) { :not_found }

        it_behaves_like 'does not enforce step-up authentication'
      end
    end
  end

  describe 'GET #activity' do
    context 'step-up authentication enforcement' do
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be(:user, reload: true) { create(:user, owner_of: group) }
      let(:expected_success_status) { :ok }

      subject(:make_request) { get activity_group_path(group) }

      before do
        sign_in(user)
      end

      it_behaves_like 'enforces step-up authentication'
    end
  end

  describe 'GET #issues' do
    context 'step-up authentication enforcement' do
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be(:user, reload: true) { create(:user, owner_of: group) }

      let(:expected_success_status) { :redirect }

      subject(:make_request) { get issues_group_path(group) }

      before do
        sign_in(user)
      end

      it_behaves_like 'enforces step-up authentication'
    end
  end

  describe 'GET #merge_requests' do
    context 'step-up authentication enforcement' do
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be(:user, reload: true) { create(:user, owner_of: group) }
      let(:expected_success_status) { :ok }

      subject(:make_request) { get merge_requests_group_path(group) }

      before do
        sign_in(user)
      end

      it_behaves_like 'enforces step-up authentication'
    end
  end

  describe 'PATCH #update' do
    context 'step-up authentication enforcement' do
      let_it_be(:group, reload: true) { create(:group) }

      subject(:make_request) { patch group_path(group), params: { group: { name: 'Updated Name' } } }

      before do
        sign_in(user)
      end

      context 'when user is owner' do
        let_it_be_with_reload(:user) { create(:user, owner_of: group) }

        let(:expected_success_status) { :found }

        it_behaves_like 'does not enforce step-up authentication'
      end

      context 'when user is maintainer' do
        let_it_be_with_reload(:user) { create(:user, maintainer_of: group) }

        let(:expected_success_status) { :not_found }

        it 'responds with 404 before step-up authentication is triggered because user is not authorized' do
          make_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'step-up authentication enforcement' do
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be(:user, reload: true) { create(:user, owner_of: group) }
      let(:expected_success_status) { :found }

      subject(:make_request) { delete group_path(group) }

      before do
        sign_in(user)
      end

      it_behaves_like 'enforces step-up authentication'
    end
  end

  describe 'PUT #transfer' do
    context 'step-up authentication enforcement' do
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be(:user, reload: true) { create(:user, owner_of: group) }
      let_it_be(:parent_group, freeze: true) { create(:group) }
      let(:expected_success_status) { :found }

      subject(:make_request) do
        put transfer_group_path(group), params: { new_parent_group_id: parent_group.id }
      end

      before do
        sign_in(user)
        parent_group.add_owner(user)
      end

      it_behaves_like 'enforces step-up authentication'
    end
  end

  describe 'POST #export' do
    context 'step-up authentication enforcement' do
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be(:user, reload: true) { create(:user, owner_of: group) }
      let(:expected_success_status) { :found }

      subject(:make_request) { post export_group_path(group) }

      before do
        sign_in(user)
      end

      it_behaves_like 'enforces step-up authentication'
    end
  end
end
