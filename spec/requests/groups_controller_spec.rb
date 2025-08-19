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
  end
end
