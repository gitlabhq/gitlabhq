# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jira referenced paths', type: :request, feature_category: :integrations do
  using RSpec::Parameterized::TableSyntax

  let(:user) { create(:user) }

  let(:group) { create(:group, name: 'group') }
  let(:sub_group) { create(:group, name: 'subgroup', parent: group) }

  let!(:group_project) { create(:project, name: 'group_project', namespace: group) }
  let!(:sub_group_project) { create(:project, name: 'sub_group_project', namespace: sub_group) }

  before do
    group.add_owner(user)

    login_as user
  end

  def redirects_to_canonical_path(jira_path, redirect_path)
    get(jira_path)

    expect(response).to redirect_to(redirect_path)
  end

  shared_examples 'redirects to jira path' do
    it 'redirects to canonical path with legacy prefix' do
      redirects_to_canonical_path "/-/jira#{jira_path}", redirect_path
    end

    it 'redirects to canonical path' do
      redirects_to_canonical_path jira_path, redirect_path
    end
  end

  let(:jira_path) { '/group/group@sub_group@sub_group_project' }
  let(:redirect_path) { '/group/sub_group/sub_group_project' }

  it_behaves_like 'redirects to jira path'

  context 'contains @ before the first /' do
    let(:jira_path) { '/group@sub_group/group@sub_group@sub_group_project' }
    let(:redirect_path) { '/group/sub_group/sub_group_project' }

    it_behaves_like 'redirects to jira path'
  end

  context 'including commit path' do
    let(:jira_path) { '/group/group@sub_group@sub_group_project/commit/1234567' }
    let(:redirect_path) { '/group/sub_group/sub_group_project/commit/1234567' }

    it_behaves_like 'redirects to jira path'

    context 'malicious path with @path' do
      let(:jira_path) { '/group/@b/commit/1234567' }
      let(:redirect_path) { '/b/commit/1234567' }

      it_behaves_like 'redirects to jira path'
    end
  end

  context 'including tree path' do
    let(:jira_path) { '/group/group@sub_group@sub_group_project/tree/1234567' }
    let(:redirect_path) { '/group/sub_group/sub_group_project/-/tree/1234567' }

    it_behaves_like 'redirects to jira path'
  end

  context 'malicious path' do
    let(:jira_path) { '/group/@@malicious.server' }
    let(:redirect_path) { '/malicious.server' }

    it_behaves_like 'redirects to jira path'

    context 'malicious path with @project' do
      let(:jira_path) { '/group/@malicious.server/tree/x' }
      let(:redirect_path) { '/malicious.server/-/tree/x' }

      it_behaves_like 'redirects to jira path'
    end
  end

  context 'regular paths with legacy prefix' do
    where(:jira_path, :redirect_path) do
      '/-/jira/group/group_project'                | '/group/group_project'
      '/-/jira/group/group_project/commit/1234567' | '/group/group_project/commit/1234567'
      '/-/jira/group/group_project/tree/1234567'   | '/group/group_project/-/tree/1234567'
    end

    with_them do
      it 'redirects to canonical path' do
        redirects_to_canonical_path jira_path, redirect_path
      end
    end
  end

  context 'when tree path has an @' do
    let(:path) { '/group/project/tree/folder-with-@' }

    it 'does not do a redirect' do
      get path

      expect(response).not_to have_gitlab_http_status(:moved_permanently)
    end
  end
end
