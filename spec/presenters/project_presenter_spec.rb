require 'spec_helper'

describe ProjectPresenter do
  let(:user) { create(:user) }

  describe '#license_short_name' do
    let(:project) { create(:project) }
    let(:presenter) { described_class.new(project, current_user: user) }

    context 'when project.repository has a license_key' do
      it 'returns the nickname of the license if present' do
        allow(project.repository).to receive(:license_key).and_return('agpl-3.0')

        expect(presenter.license_short_name).to eq('GNU AGPLv3')
      end

      it 'returns the name of the license if nickname is not present' do
        allow(project.repository).to receive(:license_key).and_return('mit')

        expect(presenter.license_short_name).to eq('MIT License')
      end
    end

    context 'when project.repository has no license_key but a license_blob' do
      it 'returns LICENSE' do
        allow(project.repository).to receive(:license_key).and_return(nil)

        expect(presenter.license_short_name).to eq('LICENSE')
      end
    end
  end

  describe '#default_view' do
    let(:presenter) { described_class.new(project, current_user: user) }

    context 'user not signed in' do
      let(:user) { nil }

      context 'when repository is empty' do
        let(:project) { create(:project_empty_repo, :public) }

        it 'returns activity if user has repository access' do
          allow(presenter).to receive(:can?).with(nil, :download_code, project).and_return(true)

          expect(presenter.default_view).to eq('activity')
        end

        it 'returns activity if user does not have repository access' do
          allow(project).to receive(:can?).with(nil, :download_code, project).and_return(false)

          expect(presenter.default_view).to eq('activity')
        end
      end

      context 'when repository is not empty' do
        let(:project) { create(:project, :public, :repository) }

        it 'returns files and readme if user has repository access' do
          allow(presenter).to receive(:can?).with(nil, :download_code, project).and_return(true)

          expect(presenter.default_view).to eq('files')
        end

        it 'returns activity if user does not have repository access' do
          allow(presenter).to receive(:can?).with(nil, :download_code, project).and_return(false)

          expect(presenter.default_view).to eq('activity')
        end
      end
    end

    context 'user signed in' do
      let(:user) { create(:user, :readme) }
      let(:project) { create(:project, :public, :repository) }

      context 'when the user is allowed to see the code' do
        it 'returns the project view' do
          allow(presenter).to receive(:can?).with(user, :download_code, project).and_return(true)

          expect(presenter.default_view).to eq('readme')
        end
      end

      context 'with wikis enabled and the right policy for the user' do
        before do
          project.project_feature.update_attribute(:issues_access_level, 0)
          allow(presenter).to receive(:can?).with(user, :download_code, project).and_return(false)
        end

        it 'returns wiki if the user has the right policy' do
          allow(presenter).to receive(:can?).with(user, :read_wiki, project).and_return(true)

          expect(presenter.default_view).to eq('wiki')
        end

        it 'returns customize_workflow if the user does not have the right policy' do
          allow(presenter).to receive(:can?).with(user, :read_wiki, project).and_return(false)

          expect(presenter.default_view).to eq('customize_workflow')
        end
      end

      context 'with issues as a feature available' do
        it 'return issues' do
          allow(presenter).to receive(:can?).with(user, :download_code, project).and_return(false)
          allow(presenter).to receive(:can?).with(user, :read_wiki, project).and_return(false)

          expect(presenter.default_view).to eq('projects/issues/issues')
        end
      end

      context 'with no activity, no wikies and no issues' do
        it 'returns customize_workflow as default' do
          project.project_feature.update_attribute(:issues_access_level, 0)
          allow(presenter).to receive(:can?).with(user, :download_code, project).and_return(false)
          allow(presenter).to receive(:can?).with(user, :read_wiki, project).and_return(false)

          expect(presenter.default_view).to eq('customize_workflow')
        end
      end
    end
  end

  describe '#can_current_user_push_code?' do
    let(:project) { create(:project, :repository) }
    let(:presenter) { described_class.new(project, current_user: user) }

    context 'empty repo' do
      let(:project) { create(:project) }

      it 'returns true if user can push_code' do
        project.add_developer(user)

        expect(presenter.can_current_user_push_code?).to be(true)
      end

      it 'returns false if user cannot push_code' do
        project.add_reporter(user)

        expect(presenter.can_current_user_push_code?).to be(false)
      end
    end

    context 'not empty repo' do
      let(:project) { create(:project, :repository) }

      it 'returns true if user can push to default branch' do
        project.add_developer(user)

        expect(presenter.can_current_user_push_code?).to be(true)
      end

      it 'returns false if default branch is protected' do
        project.add_developer(user)
        create(:protected_branch, project: project, name: project.default_branch)

        expect(presenter.can_current_user_push_code?).to be(false)
      end
    end
  end

  context 'statistics anchors' do
    let(:project) { create(:project, :repository) }
    let(:presenter) { described_class.new(project, current_user: user) }

    describe '#files_anchor_data' do
      it 'returns files data' do
        expect(presenter.files_anchor_data).to eq(OpenStruct.new(enabled: true,
                                                                 label: 'Files (0 Bytes)',
                                                                 link: presenter.project_tree_path(project)))
      end
    end

    describe '#commits_anchor_data' do
      it 'returns commits data' do
        expect(presenter.commits_anchor_data).to eq(OpenStruct.new(enabled: true,
                                                                   label: 'Commits (0)',
                                                                   link: presenter.project_commits_path(project, project.repository.root_ref)))
      end
    end

    describe '#branches_anchor_data' do
      it 'returns branches data' do
        expect(presenter.branches_anchor_data).to eq(OpenStruct.new(enabled: true,
                                                                    label: "Branches (#{project.repository.branches.size})",
                                                                    link: presenter.project_branches_path(project)))
      end
    end

    describe '#tags_anchor_data' do
      it 'returns tags data' do
        expect(presenter.tags_anchor_data).to eq(OpenStruct.new(enabled: true,
                                                                label: "Tags (#{project.repository.tags.size})",
                                                                link: presenter.project_tags_path(project)))
      end
    end

    describe '#new_file_anchor_data' do
      it 'returns new file data if user can push' do
        project.add_developer(user)

        expect(presenter.new_file_anchor_data).to eq(OpenStruct.new(enabled: false,
                                                                    label: "New file",
                                                                    link: presenter.project_new_blob_path(project, 'master'),
                                                                    class_modifier: 'new'))
      end

      it 'returns nil if user cannot push' do
        expect(presenter.new_file_anchor_data).to be_nil
      end
    end

    describe '#readme_anchor_data' do
      context 'when user can push and README does not exists' do
        it 'returns anchor data' do
          project.add_developer(user)
          allow(project.repository).to receive(:readme).and_return(nil)

          expect(presenter.readme_anchor_data).to eq(OpenStruct.new(enabled: false,
                                                                    label: 'Add Readme',
                                                                    link: presenter.add_readme_path))
        end
      end

      context 'when README exists' do
        it 'returns anchor data' do
          allow(project.repository).to receive(:readme).and_return(double(name: 'readme'))

          expect(presenter.readme_anchor_data).to eq(OpenStruct.new(enabled: true,
                                                                    label: 'Readme',
                                                                    link: presenter.readme_path))
        end
      end
    end

    describe '#changelog_anchor_data' do
      context 'when user can push and CHANGELOG does not exists' do
        it 'returns anchor data' do
          project.add_developer(user)
          allow(project.repository).to receive(:changelog).and_return(nil)

          expect(presenter.changelog_anchor_data).to eq(OpenStruct.new(enabled: false,
                                                                       label: 'Add Changelog',
                                                                       link: presenter.add_changelog_path))
        end
      end

      context 'when CHANGELOG exists' do
        it 'returns anchor data' do
          allow(project.repository).to receive(:changelog).and_return(double(name: 'foo'))

          expect(presenter.changelog_anchor_data).to eq(OpenStruct.new(enabled: true,
                                                                       label: 'Changelog',
                                                                       link: presenter.changelog_path))
        end
      end
    end

    describe '#license_anchor_data' do
      context 'when user can push and LICENSE does not exists' do
        it 'returns anchor data' do
          project.add_developer(user)
          allow(project.repository).to receive(:license_blob).and_return(nil)

          expect(presenter.license_anchor_data).to eq(OpenStruct.new(enabled: false,
                                                                     label: 'Add License',
                                                                     link: presenter.add_license_path))
        end
      end

      context 'when LICENSE exists' do
        it 'returns anchor data' do
          allow(project.repository).to receive(:license_blob).and_return(double(name: 'foo'))

          expect(presenter.license_anchor_data).to eq(OpenStruct.new(enabled: true,
                                                                     label: presenter.license_short_name,
                                                                     link: presenter.license_path))
        end
      end
    end

    describe '#contribution_guide_anchor_data' do
      context 'when user can push and CONTRIBUTING does not exists' do
        it 'returns anchor data' do
          project.add_developer(user)
          allow(project.repository).to receive(:contribution_guide).and_return(nil)

          expect(presenter.contribution_guide_anchor_data).to eq(OpenStruct.new(enabled: false,
                                                                                label: 'Add Contribution guide',
                                                                                link: presenter.add_contribution_guide_path))
        end
      end

      context 'when CONTRIBUTING exists' do
        it 'returns anchor data' do
          allow(project.repository).to receive(:contribution_guide).and_return(double(name: 'foo'))

          expect(presenter.contribution_guide_anchor_data).to eq(OpenStruct.new(enabled: true,
                                                                                label: 'Contribution guide',
                                                                                link: presenter.contribution_guide_path))
        end
      end
    end

    describe '#autodevops_anchor_data' do
      context 'when Auto Devops is enabled' do
        it 'returns anchor data' do
          allow(project).to receive(:auto_devops_enabled?).and_return(true)

          expect(presenter.autodevops_anchor_data).to eq(OpenStruct.new(enabled: true,
                                                                        label: 'Auto DevOps enabled',
                                                                        link: nil))
        end
      end

      context 'when user can admin pipeline and CI yml does not exists' do
        it 'returns anchor data' do
          project.add_master(user)
          allow(project).to receive(:auto_devops_enabled?).and_return(false)
          allow(project.repository).to receive(:gitlab_ci_yml).and_return(nil)

          expect(presenter.autodevops_anchor_data).to eq(OpenStruct.new(enabled: false,
                                                                        label: 'Enable Auto DevOps',
                                                                        link: presenter.project_settings_ci_cd_path(project, anchor: 'autodevops-settings')))
        end
      end
    end

    describe '#kubernetes_cluster_anchor_data' do
      context 'when user can create Kubernetes cluster' do
        it 'returns link to cluster if only one exists' do
          project.add_master(user)
          cluster = create(:cluster, projects: [project])

          expect(presenter.kubernetes_cluster_anchor_data).to eq(OpenStruct.new(enabled: true,
                                                                                label: 'Kubernetes configured',
                                                                                link: presenter.project_cluster_path(project, cluster)))
        end

        it 'returns link to clusters page if more than one exists' do
          project.add_master(user)
          create(:cluster, :production_environment, projects: [project])
          create(:cluster, projects: [project])

          expect(presenter.kubernetes_cluster_anchor_data).to eq(OpenStruct.new(enabled: true,
                                                                                label: 'Kubernetes configured',
                                                                                link: presenter.project_clusters_path(project)))
        end

        it 'returns link to create a cluster if no cluster exists' do
          project.add_master(user)

          expect(presenter.kubernetes_cluster_anchor_data).to eq(OpenStruct.new(enabled: false,
                                                                                label: 'Add Kubernetes cluster',
                                                                                link: presenter.new_project_cluster_path(project)))
        end
      end

      context 'when user cannot create Kubernetes cluster' do
        it 'returns nil' do
          expect(presenter.kubernetes_cluster_anchor_data).to be_nil
        end
      end
    end

    describe '#koding_anchor_data' do
      it 'returns link to setup Koding if user can push and no koding YML exists' do
        project.add_developer(user)
        allow(project.repository).to receive(:koding_yml).and_return(nil)
        allow(Gitlab::CurrentSettings).to receive(:koding_enabled?).and_return(true)

        expect(presenter.koding_anchor_data).to eq(OpenStruct.new(enabled: false,
                                                                  label: 'Set up Koding',
                                                                  link: presenter.add_koding_stack_path))
      end

      it 'returns nil if user cannot push' do
        expect(presenter.koding_anchor_data).to be_nil
      end

      it 'returns nil if koding is not enabled' do
        project.add_developer(user)
        allow(Gitlab::CurrentSettings).to receive(:koding_enabled?).and_return(false)

        expect(presenter.koding_anchor_data).to be_nil
      end

      it 'returns nil if koding YML already exists' do
        project.add_developer(user)
        allow(project.repository).to receive(:koding_yml).and_return(double)
        allow(Gitlab::CurrentSettings).to receive(:koding_enabled?).and_return(true)

        expect(presenter.koding_anchor_data).to be_nil
      end
    end
  end
end
