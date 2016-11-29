require 'spec_helper'

describe ProjectPolicy, models: true do
  let(:guest) { create(:user) }
  let(:reporter) { create(:user) }
  let(:dev) { create(:user) }
  let(:master) { create(:user) }
  let(:owner) { create(:user) }
  let(:admin) { create(:admin) }
  let(:project) { create(:empty_project, :public, namespace: owner.namespace) }

  let(:guest_permissions) do
    [
      :read_project, :read_board, :read_list, :read_wiki, :read_issue, :read_label,
      :read_milestone, :read_project_snippet, :read_project_member,
      :read_note, :create_project, :create_issue, :create_note,
      :upload_file
    ]
  end

  let(:reporter_permissions) do
    [
      :download_code, :fork_project, :create_project_snippet, :update_issue,
      :admin_issue, :admin_label, :admin_list, :read_commit_status, :read_build,
      :read_container_image, :read_pipeline, :read_environment, :read_deployment,
      :read_merge_request, :download_wiki_code
    ]
  end

  let(:team_member_reporter_permissions) do
    [
      :build_download_code, :build_read_container_image
    ]
  end

  let(:developer_permissions) do
    [
      :admin_merge_request, :update_merge_request, :create_commit_status,
      :update_commit_status, :create_build, :update_build, :create_pipeline,
      :update_pipeline, :create_merge_request, :create_wiki, :push_code,
      :resolve_note, :create_container_image, :update_container_image,
      :create_environment, :create_deployment
    ]
  end

  let(:master_permissions) do
    [
      :push_code_to_protected_branches, :update_project_snippet, :update_environment,
      :update_deployment, :admin_milestone, :admin_project_snippet,
      :admin_project_member, :admin_note, :admin_wiki, :admin_project,
      :admin_commit_status, :admin_build, :admin_container_image,
      :admin_pipeline, :admin_environment, :admin_deployment
    ]
  end

  let(:public_permissions) do
    [
      :download_code, :fork_project, :read_commit_status, :read_pipeline,
      :read_container_image, :build_download_code, :build_read_container_image,
      :download_wiki_code
    ]
  end

  let(:owner_permissions) do
    [
      :change_namespace, :change_visibility_level, :rename_project, :remove_project,
      :archive_project, :remove_fork_project, :destroy_merge_request, :destroy_issue
    ]
  end

  before do
    project.team << [guest, :guest]
    project.team << [master, :master]
    project.team << [dev, :developer]
    project.team << [reporter, :reporter]
  end

  it 'does not include the read_issue permission when the issue author is not a member of the private project' do
    project = create(:project, :private)
    issue   = create(:issue, project: project)
    user    = issue.author

    expect(project.team.member?(issue.author)).to eq(false)

    expect(BasePolicy.class_for(project).abilities(user, project).can_set).
      not_to include(:read_issue)

    expect(Ability.allowed?(user, :read_issue, project)).to be_falsy
  end

  it 'does not include the wiki permissions when the feature is disabled' do
    project.project_feature.update_attribute(:wiki_access_level, ProjectFeature::DISABLED)
    wiki_permissions = [:read_wiki, :create_wiki, :update_wiki, :admin_wiki, :download_wiki_code]

    permissions = described_class.abilities(owner, project).to_set

    expect(permissions).not_to include(*wiki_permissions)
  end

  context 'abilities for non-public projects' do
    let(:project) { create(:empty_project, namespace: owner.namespace) }

    subject { described_class.abilities(current_user, project).to_set }

    context 'with no user' do
      let(:current_user) { nil }

      it { is_expected.to be_empty }
    end

    context 'guests' do
      let(:current_user) { guest }

      it do
        is_expected.to include(*guest_permissions)
        is_expected.not_to include(*reporter_permissions)
        is_expected.not_to include(*team_member_reporter_permissions)
        is_expected.not_to include(*developer_permissions)
        is_expected.not_to include(*master_permissions)
        is_expected.not_to include(*owner_permissions)
      end
    end

    context 'reporter' do
      let(:current_user) { reporter }

      it do
        is_expected.to include(*guest_permissions)
        is_expected.to include(*reporter_permissions)
        is_expected.to include(*team_member_reporter_permissions)
        is_expected.not_to include(*developer_permissions)
        is_expected.not_to include(*master_permissions)
        is_expected.not_to include(*owner_permissions)
      end
    end

    context 'developer' do
      let(:current_user) { dev }

      it do
        is_expected.to include(*guest_permissions)
        is_expected.to include(*reporter_permissions)
        is_expected.to include(*team_member_reporter_permissions)
        is_expected.to include(*developer_permissions)
        is_expected.not_to include(*master_permissions)
        is_expected.not_to include(*owner_permissions)
      end
    end

    context 'master' do
      let(:current_user) { master }

      it do
        is_expected.to include(*guest_permissions)
        is_expected.to include(*reporter_permissions)
        is_expected.to include(*team_member_reporter_permissions)
        is_expected.to include(*developer_permissions)
        is_expected.to include(*master_permissions)
        is_expected.not_to include(*owner_permissions)
      end
    end

    context 'owner' do
      let(:current_user) { owner }

      it do
        is_expected.to include(*guest_permissions)
        is_expected.to include(*reporter_permissions)
        is_expected.to include(*team_member_reporter_permissions)
        is_expected.to include(*developer_permissions)
        is_expected.to include(*master_permissions)
        is_expected.to include(*owner_permissions)
      end
    end

    context 'admin' do
      let(:current_user) { admin }

      it do
        is_expected.to include(*guest_permissions)
        is_expected.to include(*reporter_permissions)
        is_expected.not_to include(*team_member_reporter_permissions)
        is_expected.to include(*developer_permissions)
        is_expected.to include(*master_permissions)
        is_expected.to include(*owner_permissions)
      end
    end
  end
end
