require 'spec_helper'

describe ProjectPolicy do
  include_context 'ProjectPolicy context'

  it 'does not include the read_issue permission when the issue author is not a member of the private project' do
    project = create(:project, :private)
    issue   = create(:issue, project: project, author: create(:user))
    user    = issue.author

    expect(project.team.member?(issue.author)).to be false

    expect(Ability).not_to be_allowed(user, :read_issue, project)
  end

  context 'wiki feature' do
    let(:permissions) { %i(read_wiki create_wiki update_wiki admin_wiki download_wiki_code) }

    subject { described_class.new(owner, project) }

    context 'when the feature is disabled' do
      before do
        project.project_feature.update_attribute(:wiki_access_level, ProjectFeature::DISABLED)
      end

      it 'does not include the wiki permissions' do
        expect_disallowed(*permissions)
      end

      context 'when there is an external wiki' do
        it 'does not include the wiki permissions' do
          allow(project).to receive(:has_external_wiki?).and_return(true)

          expect_disallowed(*permissions)
        end
      end
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
      project.project_feature.update(merge_requests_access_level: ProjectFeature::DISABLED)

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

  context 'builds feature' do
    context 'when builds are disabled' do
      subject { described_class.new(owner, project) }

      before do
        project.project_feature.update(builds_access_level: ProjectFeature::DISABLED)
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
        project.project_feature.update(builds_access_level: ProjectFeature::PRIVATE)
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
    subject { described_class.new(owner, project) }

    it 'disallows all permissions when the feature is disabled' do
      project.project_feature.update(repository_access_level: ProjectFeature::DISABLED)

      repository_permissions = [
        :create_pipeline, :update_pipeline, :admin_pipeline, :destroy_pipeline,
        :create_build, :read_build, :update_build, :admin_build, :destroy_build,
        :create_pipeline_schedule, :read_pipeline_schedule, :update_pipeline_schedule, :admin_pipeline_schedule, :destroy_pipeline_schedule,
        :create_environment, :read_environment, :update_environment, :admin_environment, :destroy_environment,
        :create_cluster, :read_cluster, :update_cluster, :admin_cluster,
        :create_deployment, :read_deployment, :update_deployment, :admin_deployment, :destroy_deployment,
        :destroy_release
      ]

      expect_disallowed(*repository_permissions)
    end
  end

  it_behaves_like 'project policies as anonymous'
  it_behaves_like 'project policies as guest'
  it_behaves_like 'project policies as reporter'
  it_behaves_like 'project policies as developer'
  it_behaves_like 'project policies as maintainer'
  it_behaves_like 'project policies as owner'
  it_behaves_like 'project policies as admin'

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

    it 'dissallows abilities to a maintainer if the merge request was closed' do
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
end
