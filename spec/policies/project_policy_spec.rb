# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectPolicy do
  include ExternalAuthorizationServiceHelpers
  include_context 'ProjectPolicy context'

  let(:project) { public_project }

  subject { described_class.new(current_user, project) }

  def expect_allowed(*permissions)
    permissions.each { |p| is_expected.to be_allowed(p) }
  end

  def expect_disallowed(*permissions)
    permissions.each { |p| is_expected.not_to be_allowed(p) }
  end

  context 'with no project feature' do
    let(:current_user) { owner }

    before do
      project.project_feature.destroy!
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
    let(:current_user) { owner }

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
    let(:current_user) { owner }

    it 'disallows all permissions when the feature is disabled' do
      project.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)

      mr_permissions = [:create_merge_request_from, :read_merge_request,
                        :update_merge_request, :admin_merge_request,
                        :create_merge_request_in]

      expect_disallowed(*mr_permissions)
    end
  end

  context 'for a guest in a private project' do
    let(:current_user) { guest }
    let(:project) { private_project }

    it 'disallows the guest from reading the merge request and merge request iid' do
      expect_disallowed(:read_merge_request)
      expect_disallowed(:read_merge_request_iid)
    end
  end

  context 'pipeline feature' do
    let(:project) { private_project }

    describe 'for unconfirmed user' do
      let(:current_user) { create(:user, confirmed_at: nil) }

      it 'disallows to modify pipelines' do
        expect_disallowed(:create_pipeline)
        expect_disallowed(:update_pipeline)
        expect_disallowed(:create_pipeline_schedule)
      end
    end

    describe 'for confirmed user' do
      let(:current_user) { developer }

      it 'allows modify pipelines' do
        expect_allowed(:create_pipeline)
        expect_allowed(:update_pipeline)
        expect_allowed(:create_pipeline_schedule)
      end
    end
  end

  context 'builds feature' do
    context 'when builds are disabled' do
      let(:current_user) { owner }

      before do
        project.project_feature.update!(builds_access_level: ProjectFeature::DISABLED)
      end

      it 'disallows all permissions except pipeline when the feature is disabled' do
        builds_permissions = [
          :create_build, :read_build, :update_build, :admin_build, :destroy_build,
          :create_pipeline_schedule, :read_pipeline_schedule_variables, :update_pipeline_schedule, :admin_pipeline_schedule, :destroy_pipeline_schedule,
          :create_environment, :read_environment, :update_environment, :admin_environment, :destroy_environment,
          :create_cluster, :read_cluster, :update_cluster, :admin_cluster, :destroy_cluster,
          :create_deployment, :read_deployment, :update_deployment, :admin_deployment, :destroy_deployment
        ]

        expect_disallowed(*builds_permissions)
      end
    end

    context 'when builds are disabled only for some users' do
      let(:current_user) { guest }

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
      let(:current_user) { owner }

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

    context 'when user is non-member' do
      let(:current_user) { non_member }

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
    let(:current_user) { create(:user) }
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

    it 'does not allow pushing code' do
      expect_disallowed(*maintainer_abilities)
    end

    it 'allows pushing if the user is a member with push access to the target project' do
      target_project.add_developer(current_user)

      expect_allowed(*maintainer_abilities)
    end

    it 'disallows abilities to a maintainer if the merge request was closed' do
      target_project.add_developer(current_user)
      merge_request.close!

      expect_disallowed(*maintainer_abilities)
    end
  end

  it_behaves_like 'clusterable policies' do
    let_it_be(:clusterable) { create(:project, :repository) }
    let_it_be(:cluster) do
      create(:cluster, :provided_by_gcp, :project, projects: [clusterable])
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
    context 'anonymous user' do
      let(:current_user) { anonymous }

      it { is_expected.to be_disallowed(:fork_project) }
    end

    context 'project member' do
      let(:project) { private_project }

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
    context 'when no user' do
      let(:current_user) { anonymous }

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

    it { is_expected.to be_allowed(:reporter_access) }

    context 'within a private project' do
      let(:project) { private_project }

      it { is_expected.to be_allowed(:admin_issue) }
    end
  end

  context 'support bot' do
    let(:current_user) { User.support_bot }

    context 'with service desk disabled' do
      it { expect_allowed(:guest_access) }
      it { expect_disallowed(:create_note, :read_project) }
    end

    context 'with service desk enabled' do
      before do
        allow(project).to receive(:service_desk_enabled?).and_return(true)
      end

      it { expect_allowed(:reporter_access, :create_note, :read_issue) }

      context 'when issues are protected members only' do
        before do
          project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
        end

        it { expect_allowed(:reporter_access, :create_note, :read_issue) }
      end
    end
  end

  describe 'read_prometheus_alerts' do
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
      let(:current_user) { anonymous }

      it { is_expected.to be_disallowed(:read_prometheus_alerts) }
    end
  end

  describe 'metrics_dashboard feature' do
    context 'public project' do
      let(:project) { public_project }

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
          let(:current_user) { anonymous }

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
          let(:current_user) { anonymous }

          it { is_expected.to be_allowed(:metrics_dashboard) }
          it { is_expected.to be_allowed(:read_prometheus) }
          it { is_expected.to be_allowed(:read_deployment) }
          it { is_expected.to be_disallowed(:read_metrics_user_starred_dashboard) }
          it { is_expected.to be_disallowed(:create_metrics_user_starred_dashboard) }
        end
      end
    end

    context 'internal project' do
      let(:project) { internal_project }

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
          let(:current_user) { anonymous }

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
          let(:current_user) { anonymous }

          it { is_expected.to be_disallowed(:metrics_dashboard) }
        end
      end
    end

    context 'private project' do
      let(:project) { private_project }

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
          let(:current_user) { anonymous }

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
          let(:current_user) { anonymous }

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
        let(:current_user) { anonymous }

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
      it { is_expected.to be_allowed(:read_package) }
      it { is_expected.to be_allowed(:read_project) }
      it { is_expected.to be_disallowed(:destroy_package) }
    end
  end

  describe 'create_web_ide_terminal' do
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
      let(:current_user) { non_member }

      it { is_expected.to be_disallowed(:create_web_ide_terminal) }
    end

    context 'with anonymous' do
      let(:current_user) { anonymous }

      it { is_expected.to be_disallowed(:create_web_ide_terminal) }
    end
  end

  describe 'read_repository_graphs' do
    let(:current_user) { guest }

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

  describe 'design permissions' do
    let(:current_user) { guest }

    let(:design_permissions) do
      %i[read_design_activity read_design]
    end

    context 'when design management is not available' do
      it { is_expected.not_to be_allowed(*design_permissions) }
    end

    context 'when design management is available' do
      include DesignManagementTestHelpers

      before do
        enable_design_management
      end

      it { is_expected.to be_allowed(*design_permissions) }
    end
  end

  describe 'read_build_report_results' do
    let(:current_user) { guest }

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

  describe 'read_package' do
    context 'with admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:read_package) }

      context 'when repository is disabled' do
        before do
          project.project_feature.update!(
            # Disable merge_requests and builds as well, since merge_requests and
            # builds cannot have higher visibility than repository.
            merge_requests_access_level: ProjectFeature::DISABLED,
            builds_access_level: ProjectFeature::DISABLED,
            repository_access_level: ProjectFeature::DISABLED)
        end

        it { is_expected.to be_disallowed(:read_package) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with non member' do
      let(:current_user) { non_member }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with anonymous' do
      let(:current_user) { anonymous }

      it { is_expected.to be_allowed(:read_package) }
    end
  end

  describe 'read_feature_flag' do
    subject { described_class.new(current_user, project) }

    context 'with maintainer' do
      let(:current_user) { maintainer }

      context 'when repository is available' do
        it { is_expected.to be_allowed(:read_feature_flag) }
      end

      context 'when repository is disabled' do
        before do
          project.project_feature.update!(
            merge_requests_access_level: ProjectFeature::DISABLED,
            builds_access_level: ProjectFeature::DISABLED,
            repository_access_level: ProjectFeature::DISABLED
          )
        end

        it { is_expected.to be_disallowed(:read_feature_flag) }
      end
    end

    context 'with developer' do
      let(:current_user) { developer }

      context 'when repository is available' do
        it { is_expected.to be_allowed(:read_feature_flag) }
      end
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      context 'when repository is available' do
        it { is_expected.to be_disallowed(:read_feature_flag) }
      end
    end
  end

  it_behaves_like 'Self-managed Core resource access tokens'

  describe 'operations feature' do
    using RSpec::Parameterized::TableSyntax

    let(:guest_operations_permissions) { [:read_environment, :read_deployment] }

    let(:developer_operations_permissions) do
      guest_operations_permissions + [
        :read_feature_flag, :read_sentry_issue, :read_alert_management_alert, :read_terraform_state,
        :metrics_dashboard, :read_pod_logs, :read_prometheus, :create_feature_flag,
        :create_environment, :create_deployment, :update_feature_flag, :update_environment,
        :update_sentry_issue, :update_alert_management_alert, :update_deployment,
        :destroy_feature_flag, :destroy_environment, :admin_feature_flag
      ]
    end

    let(:maintainer_operations_permissions) do
      developer_operations_permissions + [
        :read_cluster, :create_cluster, :update_cluster, :admin_environment,
        :admin_cluster, :admin_terraform_state, :admin_deployment
      ]
    end

    where(:project_visibility, :access_level, :role, :allowed) do
      :public   | ProjectFeature::ENABLED   | :maintainer | true
      :public   | ProjectFeature::ENABLED   | :developer  | true
      :public   | ProjectFeature::ENABLED   | :guest      | true
      :public   | ProjectFeature::ENABLED   | :anonymous  | true
      :public   | ProjectFeature::PRIVATE   | :maintainer | true
      :public   | ProjectFeature::PRIVATE   | :developer  | true
      :public   | ProjectFeature::PRIVATE   | :guest      | true
      :public   | ProjectFeature::PRIVATE   | :anonymous  | false
      :public   | ProjectFeature::DISABLED  | :maintainer | false
      :public   | ProjectFeature::DISABLED  | :developer  | false
      :public   | ProjectFeature::DISABLED  | :guest      | false
      :public   | ProjectFeature::DISABLED  | :anonymous  | false
      :internal | ProjectFeature::ENABLED   | :maintainer | true
      :internal | ProjectFeature::ENABLED   | :developer  | true
      :internal | ProjectFeature::ENABLED   | :guest      | true
      :internal | ProjectFeature::ENABLED   | :anonymous  | false
      :internal | ProjectFeature::PRIVATE   | :maintainer | true
      :internal | ProjectFeature::PRIVATE   | :developer  | true
      :internal | ProjectFeature::PRIVATE   | :guest      | true
      :internal | ProjectFeature::PRIVATE   | :anonymous  | false
      :internal | ProjectFeature::DISABLED  | :maintainer | false
      :internal | ProjectFeature::DISABLED  | :developer  | false
      :internal | ProjectFeature::DISABLED  | :guest      | false
      :internal | ProjectFeature::DISABLED  | :anonymous  | false
      :private  | ProjectFeature::ENABLED   | :maintainer | true
      :private  | ProjectFeature::ENABLED   | :developer  | true
      :private  | ProjectFeature::ENABLED   | :guest      | false
      :private  | ProjectFeature::ENABLED   | :anonymous  | false
      :private  | ProjectFeature::PRIVATE   | :maintainer | true
      :private  | ProjectFeature::PRIVATE   | :developer  | true
      :private  | ProjectFeature::PRIVATE   | :guest      | false
      :private  | ProjectFeature::PRIVATE   | :anonymous  | false
      :private  | ProjectFeature::DISABLED  | :maintainer | false
      :private  | ProjectFeature::DISABLED  | :developer  | false
      :private  | ProjectFeature::DISABLED  | :guest      | false
      :private  | ProjectFeature::DISABLED  | :anonymous  | false
    end

    with_them do
      let(:current_user) { user_subject(role) }
      let(:project) { project_subject(project_visibility) }

      it 'allows/disallows the abilities based on the operation feature access level' do
        project.project_feature.update!(operations_access_level: access_level)

        if allowed
          expect_allowed(*permissions_abilities(role))
        else
          expect_disallowed(*permissions_abilities(role))
        end
      end

      def project_subject(project_type)
        case project_type
        when :public
          public_project
        when :internal
          internal_project
        else
          private_project
        end
      end

      def user_subject(role)
        case role
        when :maintainer
          maintainer
        when :developer
          developer
        when :guest
          guest
        when :anonymous
          anonymous
        end
      end

      def permissions_abilities(role)
        case role
        when :maintainer
          maintainer_operations_permissions
        when :developer
          developer_operations_permissions
        else
          guest_operations_permissions
        end
      end
    end
  end
end
