# frozen_string_literal: true

require 'spec_helper'

describe ProjectPolicy do
  include ExternalAuthorizationServiceHelpers
  include_context 'ProjectPolicy context'
  let_it_be(:other_user) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let(:project) { create(:project, :public, namespace: owner.namespace) }

  let(:base_guest_permissions) do
    %i[
      read_project read_board read_list read_wiki read_issue
      read_project_for_iids read_issue_iid read_label
      read_milestone read_snippet read_project_member read_note
      create_project create_issue create_note upload_file create_merge_request_in
      award_emoji read_release
    ]
  end

  let(:base_reporter_permissions) do
    %i[
      download_code fork_project create_snippet update_issue
      admin_issue admin_label admin_list read_commit_status read_build
      read_container_image read_pipeline read_environment read_deployment
      read_merge_request download_wiki_code read_sentry_issue read_metrics_dashboard_annotation
      metrics_dashboard
    ]
  end

  let(:team_member_reporter_permissions) do
    %i[build_download_code build_read_container_image]
  end

  let(:developer_permissions) do
    %i[
      admin_tag admin_milestone admin_merge_request update_merge_request create_commit_status
      update_commit_status create_build update_build create_pipeline
      update_pipeline create_merge_request_from create_wiki push_code
      resolve_note create_container_image update_container_image destroy_container_image daily_statistics
      create_environment update_environment create_deployment update_deployment create_release update_release
      create_metrics_dashboard_annotation delete_metrics_dashboard_annotation update_metrics_dashboard_annotation
    ]
  end

  let(:base_maintainer_permissions) do
    %i[
      push_to_delete_protected_branch update_snippet
      admin_snippet admin_project_member admin_note admin_wiki admin_project
      admin_commit_status admin_build admin_container_image
      admin_pipeline admin_environment admin_deployment destroy_release add_cluster
      read_deploy_token create_deploy_token destroy_deploy_token
      admin_terraform_state
    ]
  end

  let(:public_permissions) do
    %i[
      download_code fork_project read_commit_status read_pipeline
      read_container_image build_download_code build_read_container_image
      download_wiki_code read_release
    ]
  end

  let(:owner_permissions) do
    %i[
      change_namespace change_visibility_level rename_project remove_project
      archive_project remove_fork_project destroy_merge_request destroy_issue
      set_issue_iid set_issue_created_at set_issue_updated_at set_note_created_at
    ]
  end

  # Used in EE specs
  let(:additional_guest_permissions) { [] }
  let(:additional_reporter_permissions) { [] }
  let(:additional_maintainer_permissions) { [] }

  let(:guest_permissions) { base_guest_permissions + additional_guest_permissions }
  let(:reporter_permissions) { base_reporter_permissions + additional_reporter_permissions }
  let(:maintainer_permissions) { base_maintainer_permissions + additional_maintainer_permissions }

  before do
    project.add_guest(guest)
    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)
  end

  def expect_allowed(*permissions)
    permissions.each { |p| is_expected.to be_allowed(p) }
  end

  def expect_disallowed(*permissions)
    permissions.each { |p| is_expected.not_to be_allowed(p) }
  end

  context 'with no project feature' do
    subject { described_class.new(owner, project) }

    before do
      project.project_feature.destroy
      project.reload
    end

    it 'returns false' do
      is_expected.to be_disallowed(:read_build)
    end
  end

  it 'does not include the read_issue permission when the issue author is not a member of the private project' do
    project = create(:project, :private)
    issue   = create(:issue, project: project, author: create(:user))
    user    = issue.author

    expect(project.team.member?(issue.author)).to be false

    expect(Ability).not_to be_allowed(user, :read_issue, project)
  end

  it_behaves_like 'model with wiki policies' do
    let(:container) { project }
    let_it_be(:user) { owner }

    def set_access_level(access_level)
      project.project_feature.update_attribute(:wiki_access_level, access_level)
    end
  end

  context 'issues feature' do
    subject { described_class.new(owner, project) }

    context 'when the feature is disabled' do
      before do
        project.issues_enabled = false
        project.save!
      end

      it 'does not include the issues permissions' do
        expect_disallowed :read_issue, :read_issue_iid, :create_issue, :update_issue, :admin_issue
      end

      it 'disables boards and lists permissions' do
        expect_disallowed :read_board, :create_board, :update_board
        expect_disallowed :read_list, :create_list, :update_list, :admin_list
      end

      context 'when external tracker configured' do
        it 'does not include the issues permissions' do
          create(:jira_service, project: project)

          expect_disallowed :read_issue, :read_issue_iid, :create_issue, :update_issue, :admin_issue
        end
      end
    end
  end

  context 'merge requests feature' do
    subject { described_class.new(owner, project) }

    it 'disallows all permissions when the feature is disabled' do
      project.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)

      mr_permissions = [:create_merge_request_from, :read_merge_request,
                        :update_merge_request, :admin_merge_request,
                        :create_merge_request_in]

      expect_disallowed(*mr_permissions)
    end
  end

  context 'for a guest in a private project' do
    let(:project) { create(:project, :private) }

    subject { described_class.new(guest, project) }

    it 'disallows the guest from reading the merge request and merge request iid' do
      expect_disallowed(:read_merge_request)
      expect_disallowed(:read_merge_request_iid)
    end
  end

  context 'pipeline feature' do
    let(:project) { create(:project) }

    describe 'for unconfirmed user' do
      let(:unconfirmed_user) { create(:user, confirmed_at: nil) }

      subject { described_class.new(unconfirmed_user, project) }

      it 'disallows to modify pipelines' do
        expect_disallowed(:create_pipeline)
        expect_disallowed(:update_pipeline)
        expect_disallowed(:create_pipeline_schedule)
      end
    end

    describe 'for confirmed user' do
      subject { described_class.new(developer, project) }

      it 'allows modify pipelines' do
        expect_allowed(:create_pipeline)
        expect_allowed(:update_pipeline)
        expect_allowed(:create_pipeline_schedule)
      end
    end
  end

  context 'builds feature' do
    context 'when builds are disabled' do
      subject { described_class.new(owner, project) }

      before do
        project.project_feature.update!(builds_access_level: ProjectFeature::DISABLED)
      end

      it 'disallows all permissions except pipeline when the feature is disabled' do
        builds_permissions = [
          :create_build, :read_build, :update_build, :admin_build, :destroy_build,
          :create_pipeline_schedule, :read_pipeline_schedule, :update_pipeline_schedule, :admin_pipeline_schedule, :destroy_pipeline_schedule,
          :create_environment, :read_environment, :update_environment, :admin_environment, :destroy_environment,
          :create_cluster, :read_cluster, :update_cluster, :admin_cluster, :destroy_cluster,
          :create_deployment, :read_deployment, :update_deployment, :admin_deployment, :destroy_deployment
        ]

        expect_disallowed(*builds_permissions)
      end
    end

    context 'when builds are disabled only for some users' do
      subject { described_class.new(guest, project) }

      before do
        project.project_feature.update!(builds_access_level: ProjectFeature::PRIVATE)
      end

      it 'disallows pipeline and commit_status permissions' do
        builds_permissions = [
          :create_pipeline, :update_pipeline, :admin_pipeline, :destroy_pipeline,
          :create_commit_status, :update_commit_status, :admin_commit_status, :destroy_commit_status
        ]

        expect_disallowed(*builds_permissions)
      end
    end
  end

  context 'repository feature' do
    let(:repository_permissions) do
      [
        :create_pipeline, :update_pipeline, :admin_pipeline, :destroy_pipeline,
        :create_build, :read_build, :update_build, :admin_build, :destroy_build,
        :create_pipeline_schedule, :read_pipeline_schedule, :update_pipeline_schedule, :admin_pipeline_schedule, :destroy_pipeline_schedule,
        :create_environment, :read_environment, :update_environment, :admin_environment, :destroy_environment,
        :create_cluster, :read_cluster, :update_cluster, :admin_cluster,
        :create_deployment, :read_deployment, :update_deployment, :admin_deployment, :destroy_deployment,
        :destroy_release, :download_code, :build_download_code
      ]
    end

    context 'when user is a project member' do
      subject { described_class.new(owner, project) }

      context 'when it is disabled' do
        before do
          project.project_feature.update!(
            repository_access_level: ProjectFeature::DISABLED,
            merge_requests_access_level: ProjectFeature::DISABLED,
            builds_access_level: ProjectFeature::DISABLED,
            forking_access_level: ProjectFeature::DISABLED
          )
        end

        it 'disallows all permissions' do
          expect_disallowed(*repository_permissions)
        end
      end
    end

    context 'when user is some other user' do
      subject { described_class.new(other_user, project) }

      context 'when access level is private' do
        before do
          project.project_feature.update!(
            repository_access_level: ProjectFeature::PRIVATE,
            merge_requests_access_level: ProjectFeature::PRIVATE,
            builds_access_level: ProjectFeature::PRIVATE,
            forking_access_level: ProjectFeature::PRIVATE
          )
        end

        it 'disallows all permissions' do
          expect_disallowed(*repository_permissions)
        end
      end
    end
  end

  it_behaves_like 'project policies as anonymous'
  it_behaves_like 'project policies as guest'
  it_behaves_like 'project policies as reporter'
  it_behaves_like 'project policies as developer'
  it_behaves_like 'project policies as maintainer'
  it_behaves_like 'project policies as owner'
  it_behaves_like 'project policies as admin with admin mode'
  it_behaves_like 'project policies as admin without admin mode'

  context 'when a public project has merge requests allowing access' do
    include ProjectForksHelper
    let(:user) { create(:user) }
    let(:target_project) { create(:project, :public) }
    let(:project) { fork_project(target_project) }
    let!(:merge_request) do
      create(
        :merge_request,
        target_project: target_project,
        source_project: project,
        allow_collaboration: true
      )
    end
    let(:maintainer_abilities) do
      %w(create_build create_pipeline)
    end

    subject { described_class.new(user, project) }

    it 'does not allow pushing code' do
      expect_disallowed(*maintainer_abilities)
    end

    it 'allows pushing if the user is a member with push access to the target project' do
      target_project.add_developer(user)

      expect_allowed(*maintainer_abilities)
    end

    it 'disallows abilities to a maintainer if the merge request was closed' do
      target_project.add_developer(user)
      merge_request.close!

      expect_disallowed(*maintainer_abilities)
    end
  end

  it_behaves_like 'clusterable policies' do
    let(:clusterable) { create(:project, :repository) }
    let(:cluster) do
      create(:cluster,
             :provided_by_gcp,
             :project,
             projects: [clusterable])
    end
  end

  context 'reading a project' do
    it 'allows access when a user has read access to the repo' do
      expect(described_class.new(owner, project)).to be_allowed(:read_project)
      expect(described_class.new(developer, project)).to be_allowed(:read_project)
      expect(described_class.new(admin, project)).to be_allowed(:read_project)
    end

    it 'never checks the external service' do
      expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

      expect(described_class.new(owner, project)).to be_allowed(:read_project)
    end

    context 'with an external authorization service' do
      before do
        enable_external_authorization_service_check
      end

      it 'allows access when the external service allows it' do
        external_service_allow_access(owner, project)
        external_service_allow_access(developer, project)

        expect(described_class.new(owner, project)).to be_allowed(:read_project)
        expect(described_class.new(developer, project)).to be_allowed(:read_project)
      end

      context 'with an admin' do
        context 'when admin mode is enabled', :enable_admin_mode do
          it 'does not check the external service and allows access' do
            expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

            expect(described_class.new(admin, project)).to be_allowed(:read_project)
          end
        end

        context 'when admin mode is disabled' do
          it 'checks the external service and allows access' do
            external_service_allow_access(admin, project)

            expect(::Gitlab::ExternalAuthorization).to receive(:access_allowed?)

            expect(described_class.new(admin, project)).to be_allowed(:read_project)
          end
        end
      end

      it 'prevents all but seeing a public project in a list when access is denied' do
        [developer, owner, build(:user), nil].each do |user|
          external_service_deny_access(user, project)
          policy = described_class.new(user, project)

          expect(policy).not_to be_allowed(:read_project)
          expect(policy).not_to be_allowed(:owner_access)
          expect(policy).not_to be_allowed(:change_namespace)
        end
      end

      it 'passes the full path to external authorization for logging purposes' do
        expect(::Gitlab::ExternalAuthorization)
          .to receive(:access_allowed?).with(owner, 'default_label', project.full_path).and_call_original

        described_class.new(owner, project).allowed?(:read_project)
      end
    end
  end

  context 'forking a project' do
    subject { described_class.new(current_user, project) }

    context 'anonymous user' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:fork_project) }
    end

    context 'project member' do
      let_it_be(:project) { create(:project, :private) }

      context 'guest' do
        let(:current_user) { guest }

        it { is_expected.to be_disallowed(:fork_project) }
      end

      %w(reporter developer maintainer).each do |role|
        context role do
          let(:current_user) { send(role) }

          it { is_expected.to be_allowed(:fork_project) }
        end
      end
    end
  end

  describe 'update_max_artifacts_size' do
    subject { described_class.new(current_user, project) }

    context 'when no user' do
      let(:current_user) { nil }

      it { expect_disallowed(:update_max_artifacts_size) }
    end

    context 'admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { expect_allowed(:update_max_artifacts_size) }
      end

      context 'when admin mode is disabled' do
        it { expect_disallowed(:update_max_artifacts_size) }
      end
    end

    %w(guest reporter developer maintainer owner).each do |role|
      context role do
        let(:current_user) { send(role) }

        it { expect_disallowed(:update_max_artifacts_size) }
      end
    end
  end

  context 'alert bot' do
    let(:current_user) { User.alert_bot }

    subject { described_class.new(current_user, project) }

    it { is_expected.to be_allowed(:reporter_access) }

    context 'within a private project' do
      let(:project) { create(:project, :private) }

      it { is_expected.to be_allowed(:admin_issue) }
    end
  end

  describe 'read_prometheus_alerts' do
    subject { described_class.new(current_user, project) }

    context 'with admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:read_prometheus_alerts) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:read_prometheus_alerts) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:read_prometheus_alerts) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:read_prometheus_alerts) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_disallowed(:read_prometheus_alerts) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:read_prometheus_alerts) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:read_prometheus_alerts) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:read_prometheus_alerts) }
    end
  end

  describe 'metrics_dashboard feature' do
    subject { described_class.new(current_user, project) }

    context 'public project' do
      let(:project) { create(:project, :public) }

      context 'feature private' do
        context 'with reporter' do
          let(:current_user) { reporter }

          it { is_expected.to be_allowed(:metrics_dashboard) }
          it { is_expected.to be_allowed(:read_prometheus) }
          it { is_expected.to be_allowed(:read_deployment) }
          it { is_expected.to be_allowed(:read_metrics_user_starred_dashboard) }
          it { is_expected.to be_allowed(:create_metrics_user_starred_dashboard) }
        end

        context 'with guest' do
          let(:current_user) { guest }

          it { is_expected.to be_disallowed(:metrics_dashboard) }
        end

        context 'with anonymous' do
          let(:current_user) { nil }

          it { is_expected.to be_disallowed(:metrics_dashboard) }
        end
      end

      context 'feature enabled' do
        before do
          project.project_feature.update!(metrics_dashboard_access_level: ProjectFeature::ENABLED)
        end

        context 'with reporter' do
          let(:current_user) { reporter }

          it { is_expected.to be_allowed(:metrics_dashboard) }
          it { is_expected.to be_allowed(:read_prometheus) }
          it { is_expected.to be_allowed(:read_deployment) }
          it { is_expected.to be_allowed(:read_metrics_user_starred_dashboard) }
          it { is_expected.to be_allowed(:create_metrics_user_starred_dashboard) }
        end

        context 'with guest' do
          let(:current_user) { guest }

          it { is_expected.to be_allowed(:metrics_dashboard) }
          it { is_expected.to be_allowed(:read_prometheus) }
          it { is_expected.to be_allowed(:read_deployment) }
          it { is_expected.to be_allowed(:read_metrics_user_starred_dashboard) }
          it { is_expected.to be_allowed(:create_metrics_user_starred_dashboard) }
        end

        context 'with anonymous' do
          let(:current_user) { nil }

          it { is_expected.to be_allowed(:metrics_dashboard) }
          it { is_expected.to be_allowed(:read_prometheus) }
          it { is_expected.to be_allowed(:read_deployment) }
          it { is_expected.to be_disallowed(:read_metrics_user_starred_dashboard) }
          it { is_expected.to be_disallowed(:create_metrics_user_starred_dashboard) }
        end
      end
    end

    context 'internal project' do
      let(:project) { create(:project, :internal) }

      context 'feature private' do
        context 'with reporter' do
          let(:current_user) { reporter }

          it { is_expected.to be_allowed(:metrics_dashboard) }
          it { is_expected.to be_allowed(:read_prometheus) }
          it { is_expected.to be_allowed(:read_deployment) }
          it { is_expected.to be_allowed(:read_metrics_user_starred_dashboard) }
          it { is_expected.to be_allowed(:create_metrics_user_starred_dashboard) }
        end

        context 'with guest' do
          let(:current_user) { guest }

          it { is_expected.to be_disallowed(:metrics_dashboard) }
        end

        context 'with anonymous' do
          let(:current_user) { nil }

          it { is_expected.to be_disallowed(:metrics_dashboard)}
        end
      end

      context 'feature enabled' do
        before do
          project.project_feature.update!(metrics_dashboard_access_level: ProjectFeature::ENABLED)
        end

        context 'with reporter' do
          let(:current_user) { reporter }

          it { is_expected.to be_allowed(:metrics_dashboard) }
          it { is_expected.to be_allowed(:read_prometheus) }
          it { is_expected.to be_allowed(:read_deployment) }
          it { is_expected.to be_allowed(:read_metrics_user_starred_dashboard) }
          it { is_expected.to be_allowed(:create_metrics_user_starred_dashboard) }
        end

        context 'with guest' do
          let(:current_user) { guest }

          it { is_expected.to be_allowed(:metrics_dashboard) }
          it { is_expected.to be_allowed(:read_prometheus) }
          it { is_expected.to be_allowed(:read_deployment) }
          it { is_expected.to be_allowed(:read_metrics_user_starred_dashboard) }
          it { is_expected.to be_allowed(:create_metrics_user_starred_dashboard) }
        end

        context 'with anonymous' do
          let(:current_user) { nil }

          it { is_expected.to be_disallowed(:metrics_dashboard) }
        end
      end
    end

    context 'private project' do
      let(:project) { create(:project, :private) }

      context 'feature private' do
        context 'with reporter' do
          let(:current_user) { reporter }

          it { is_expected.to be_allowed(:metrics_dashboard) }
          it { is_expected.to be_allowed(:read_prometheus) }
          it { is_expected.to be_allowed(:read_deployment) }
          it { is_expected.to be_allowed(:read_metrics_user_starred_dashboard) }
          it { is_expected.to be_allowed(:create_metrics_user_starred_dashboard) }
        end

        context 'with guest' do
          let(:current_user) { guest }

          it { is_expected.to be_disallowed(:metrics_dashboard) }
        end

        context 'with anonymous' do
          let(:current_user) { nil }

          it { is_expected.to be_disallowed(:metrics_dashboard) }
        end
      end

      context 'feature enabled' do
        context 'with reporter' do
          let(:current_user) { reporter }

          it { is_expected.to be_allowed(:metrics_dashboard) }
          it { is_expected.to be_allowed(:read_prometheus) }
          it { is_expected.to be_allowed(:read_deployment) }
          it { is_expected.to be_allowed(:read_metrics_user_starred_dashboard) }
          it { is_expected.to be_allowed(:create_metrics_user_starred_dashboard) }
        end

        context 'with guest' do
          let(:current_user) { guest }

          it { is_expected.to be_disallowed(:metrics_dashboard) }
        end

        context 'with anonymous' do
          let(:current_user) { nil }

          it { is_expected.to be_disallowed(:metrics_dashboard) }
        end
      end
    end

    context 'feature disabled' do
      before do
        project.project_feature.update!(metrics_dashboard_access_level: ProjectFeature::DISABLED)
      end

      context 'with reporter' do
        let(:current_user) { reporter }

        it { is_expected.to be_disallowed(:metrics_dashboard) }
      end

      context 'with guest' do
        let(:current_user) { guest }

        it { is_expected.to be_disallowed(:metrics_dashboard) }
      end

      context 'with anonymous' do
        let(:current_user) { nil }

        it { is_expected.to be_disallowed(:metrics_dashboard) }
      end
    end
  end

  context 'deploy token access' do
    let!(:project_deploy_token) do
      create(:project_deploy_token, project: project, deploy_token: deploy_token)
    end

    subject { described_class.new(deploy_token, project) }

    context 'a deploy token with read_package_registry scope' do
      let(:deploy_token) { create(:deploy_token, read_package_registry: true) }

      it { is_expected.to be_allowed(:read_package) }
      it { is_expected.to be_allowed(:read_project) }
      it { is_expected.to be_disallowed(:create_package) }
    end

    context 'a deploy token with write_package_registry scope' do
      let(:deploy_token) { create(:deploy_token, write_package_registry: true) }

      it { is_expected.to be_allowed(:create_package) }
      it { is_expected.to be_allowed(:read_project) }
      it { is_expected.to be_disallowed(:destroy_package) }
    end
  end

  describe 'create_web_ide_terminal' do
    subject { described_class.new(current_user, project) }

    context 'with admin' do
      let(:current_user) { admin }

      context 'when admin mode enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:create_web_ide_terminal) }
      end

      context 'when admin mode disabled' do
        it { is_expected.to be_disallowed(:create_web_ide_terminal) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:create_web_ide_terminal) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:create_web_ide_terminal) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_disallowed(:create_web_ide_terminal) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:create_web_ide_terminal) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:create_web_ide_terminal) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:create_web_ide_terminal) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:create_web_ide_terminal) }
    end
  end

  describe 'read_repository_graphs' do
    subject { described_class.new(guest, project) }

    before do
      allow(subject).to receive(:allowed?).with(:read_repository_graphs).and_call_original
      allow(subject).to receive(:allowed?).with(:download_code).and_return(can_download_code)
    end

    context 'when user can download_code' do
      let(:can_download_code) { true }

      it { is_expected.to be_allowed(:read_repository_graphs) }
    end

    context 'when user cannot download_code' do
      let(:can_download_code) { false }

      it { is_expected.to be_disallowed(:read_repository_graphs) }
    end
  end

  describe 'read_build_report_results' do
    subject { described_class.new(guest, project) }

    before do
      allow(subject).to receive(:allowed?).with(:read_build_report_results).and_call_original
      allow(subject).to receive(:allowed?).with(:read_build).and_return(can_read_build)
      allow(subject).to receive(:allowed?).with(:read_pipeline).and_return(can_read_pipeline)
    end

    context 'when user can read_build and read_pipeline' do
      let(:can_read_build) { true }
      let(:can_read_pipeline) { true }

      it { is_expected.to be_allowed(:read_build_report_results) }
    end

    context 'when user can read_build but cannot read_pipeline' do
      let(:can_read_build) { true }
      let(:can_read_pipeline) { false }

      it { is_expected.to be_disallowed(:read_build_report_results) }
    end

    context 'when user cannot read_build but can read_pipeline' do
      let(:can_read_build) { false }
      let(:can_read_pipeline) { true }

      it { is_expected.to be_disallowed(:read_build_report_results) }
    end

    context 'when user cannot read_build and cannot read_pipeline' do
      let(:can_read_build) { false }
      let(:can_read_pipeline) { false }

      it { is_expected.to be_disallowed(:read_build_report_results) }
    end
  end
end
