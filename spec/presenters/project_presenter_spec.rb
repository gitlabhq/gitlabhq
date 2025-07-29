# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectPresenter do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:presenter) { described_class.new(project, current_user: user) }

  describe '#license_short_name' do
    context 'when project.repository has a license_key' do
      it 'returns the nickname of the license if present' do
        allow(project.repository).to receive(:license).and_return(
          ::Gitlab::Git::DeclaredLicense.new(name: 'foo', nickname: 'GNU AGPLv3'))

        expect(presenter.license_short_name).to eq('GNU AGPLv3')
      end

      it 'returns the name of the license if nickname is not present' do
        allow(project.repository).to receive(:license).and_return(
          ::Gitlab::Git::DeclaredLicense.new(name: 'MIT License'))

        expect(presenter.license_short_name).to eq('MIT License')
      end
    end

    context 'when project.repository has no license_key but a license_blob' do
      it 'returns LICENSE' do
        allow(project.repository).to receive(:license).and_return(nil)

        expect(presenter.license_short_name).to eq('LICENSE')
      end
    end
  end

  describe '#default_view' do
    context 'user not signed in' do
      let_it_be(:user) { nil }

      context 'when repository is empty' do
        let_it_be(:project) { create(:project_empty_repo, :public) }

        it 'returns wiki if user has repository access and can read wiki, which exists' do
          allow(project).to receive(:wiki_repository_exists?).and_return(true)
          allow(presenter).to receive(:can?).with(nil, :download_code, project).and_return(true)
          allow(presenter).to receive(:can?).with(nil, :read_wiki, project).and_return(true)
          allow(presenter).to receive(:can?).with(nil, :read_issue, project).and_return(false)

          expect(presenter.default_view).to eq('wiki')
        end

        it 'returns activity if user has repository access and can read wiki, which does not exist' do
          allow(presenter).to receive(:can?).with(nil, :download_code, project).and_return(true)
          allow(presenter).to receive(:can?).with(nil, :read_wiki, project).and_return(true)
          allow(presenter).to receive(:can?).with(nil, :read_issue, project).and_return(false)

          expect(presenter.default_view).to eq('activity')
        end

        it 'returns issues if user does not have repository access, but can read issues' do
          allow(presenter).to receive(:can?).with(nil, :download_code, project).and_return(false)
          allow(presenter).to receive(:can?).with(nil, :read_issue, project).and_call_original

          expect(presenter.default_view).to eq('projects/issues')
        end

        it 'returns activity if user can read neither wiki nor issues' do
          allow(presenter).to receive(:can?).with(nil, :download_code, project).and_return(false)
          allow(presenter).to receive(:can?).with(nil, :read_issue, project).and_return(false)

          expect(presenter.default_view).to eq('activity')
        end
      end

      context 'when repository is not empty' do
        let_it_be(:project) { create(:project, :public, :repository) }

        it 'returns files and readme if user has repository access' do
          allow(presenter).to receive(:can?).with(nil, :read_code, project).and_return(true)

          expect(presenter.default_view).to eq('files')
        end

        it 'returns wiki if user does not have repository access and can read wiki, which exists' do
          allow(project).to receive(:wiki_repository_exists?).and_return(true)
          allow(presenter).to receive(:can?).with(nil, :read_code, project).and_return(false)
          allow(presenter).to receive(:can?).with(nil, :read_wiki, project).and_return(true)

          expect(presenter.default_view).to eq('wiki')
        end

        it 'returns activity if user does not have repository or wiki access' do
          allow(presenter).to receive(:can?).with(nil, :read_code, project).and_return(false)
          allow(presenter).to receive(:can?).with(nil, :read_issue, project).and_return(false)
          allow(presenter).to receive(:can?).with(nil, :read_wiki, project).and_return(false)

          expect(presenter.default_view).to eq('activity')
        end

        it 'returns releases anchor' do
          user = create(:user)
          release = create(:release, project: project, author: user)

          expect(release).to be_truthy
          expect(presenter.releases_anchor_data).to have_attributes(
            is_link: true,
            label: a_string_including(project.releases.count.to_s),
            link: presenter.project_releases_path(project)
          )
        end

        it 'returns environments anchor' do
          environment = create(:environment, project: project)
          unavailable_environment = create(:environment, project: project)
          unavailable_environment.stop

          expect(environment).to be_truthy
          expect(presenter.environments_anchor_data).to have_attributes(
            is_link: true,
            label: a_string_including(project.environments.available.count.to_s),
            link: presenter.project_environments_path(project)
          )
        end
      end
    end

    context 'user signed in' do
      let(:user) { create(:user, :readme) }
      let(:project) { create(:project, :public, :repository) }

      context 'when the user is allowed to see the code' do
        it 'returns the project view' do
          allow(presenter).to receive(:can?).with(user, :read_code, project).and_return(true)

          expect(presenter.default_view).to eq('readme')
        end
      end

      context 'with wikis enabled and the right policy for the user' do
        before do
          project.project_feature.update_attribute(:issues_access_level, 0)
          allow(presenter).to receive(:can?).with(user, :read_code, project).and_return(false)
        end

        it 'returns wiki if the user has the right policy and the wiki exists' do
          allow(project).to receive(:wiki_repository_exists?).and_return(true)
          allow(presenter).to receive(:can?).with(user, :read_wiki, project).and_return(true)

          expect(presenter.default_view).to eq('wiki')
        end

        it 'returns activity if the user does not have the right policy' do
          allow(presenter).to receive(:can?).with(user, :read_wiki, project).and_return(false)
          allow(presenter).to receive(:can?).with(user, :read_issue, project).and_return(false)

          expect(presenter.default_view).to eq('activity')
        end
      end

      context 'with issues as a feature available' do
        it 'return issues' do
          allow(presenter).to receive(:can?).with(user, :read_code, project).and_return(false)
          allow(presenter).to receive(:can?).with(user, :read_issue, project).and_return(true)
          allow(presenter).to receive(:can?).with(user, :read_wiki, project).and_return(false)

          expect(presenter.default_view).to eq('projects/issues')
        end
      end

      context 'with no activity, no wikies and no issues' do
        it 'returns activity as default' do
          project.project_feature.update_attribute(:issues_access_level, 0)
          allow(presenter).to receive(:can?).with(user, :read_code, project).and_return(false)
          allow(presenter).to receive(:can?).with(user, :read_wiki, project).and_return(false)
          allow(presenter).to receive(:can?).with(user, :read_issue, project).and_return(false)

          expect(presenter.default_view).to eq('activity')
        end
      end
    end
  end

  describe '#can_current_user_push_code?' do
    context 'empty repo' do
      let_it_be(:project) { create(:project) }

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

      context 'if no current user' do
        let(:user) { nil }

        it 'returns false' do
          expect(presenter.can_current_user_push_code?).to be(false)
        end
      end

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

  context 'statistics anchors (empty repo)' do
    let_it_be(:project) { create(:project, :empty_repo) }

    describe '#storage_anchor_data' do
      it 'does not return storage data' do
        expect(presenter.storage_anchor_data).to be_nil
      end
    end

    describe '#releases_anchor_data' do
      it 'does not return release count' do
        expect(presenter.releases_anchor_data).to be_nil
      end
    end

    describe '#commits_anchor_data' do
      it 'returns commits data' do
        expect(presenter.commits_anchor_data).to have_attributes(
          is_link: true,
          label: a_string_including('0'),
          link: nil
        )
      end
    end

    describe '#branches_anchor_data' do
      it 'returns branches data' do
        expect(presenter.branches_anchor_data).to have_attributes(
          is_link: true,
          label: a_string_including('0'),
          link: nil
        )
      end
    end

    describe '#tags_anchor_data' do
      it 'returns tags data' do
        expect(presenter.tags_anchor_data).to have_attributes(
          is_link: true,
          label: a_string_including('0'),
          link: nil
        )
      end
    end

    describe '#pages_anchor_data' do
      it 'does not return pages url' do
        expect(presenter.pages_anchor_data).to be_nil
      end
    end
  end

  context 'statistics anchors' do
    let_it_be(:user)    { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:release) { create(:release, project: project, author: user) }

    let(:presenter) { described_class.new(project, current_user: user) }

    describe '#storage_anchor_data' do
      it 'does not return storage data for non-admin users' do
        expect(presenter.storage_anchor_data).to be_nil
      end

      it 'returns storage data with usage quotas link for admin users' do
        project.add_owner(user)

        expect(presenter.storage_anchor_data).to have_attributes(
          is_link: true,
          label: a_string_including('0 B'),
          link: presenter.project_usage_quotas_path(project)
        )
      end

      describe '#gitlab_ci_anchor_data' do
        before do
          project.update!(auto_devops_enabled: false)
        end

        context 'when user cannot collaborate' do
          it 'returns no value' do
            expect(presenter.gitlab_ci_anchor_data).to be_nil
          end
        end

        context 'when user can collaborate' do
          before do
            project.add_developer(user)
          end

          context 'and the CI/CD file is missing' do
            it 'returns `Set up CI/CD` button' do
              expect(presenter.gitlab_ci_anchor_data).to have_attributes(
                is_link: false,
                label: a_string_including('Set up CI/CD'),
                link: presenter.project_ci_pipeline_editor_path(project)
              )
            end
          end

          context 'and there is a CI/CD file' do
            it 'returns `CI/CD configuration` button' do
              allow(project).to receive(:has_ci_config_file?).and_return true

              expect(presenter.gitlab_ci_anchor_data).to have_attributes(
                is_link: false,
                label: a_string_including('CI/CD configuration'),
                link: presenter.project_ci_pipeline_editor_path(project)
              )
            end
          end
        end
      end
    end

    describe '#releases_anchor_data' do
      it 'returns release count if user can read release' do
        project.add_maintainer(user)

        expect(release).to be_truthy
        expect(presenter.releases_anchor_data).to have_attributes(
          is_link: true,
          label: a_string_including(project.releases.count.to_s),
          link: presenter.project_releases_path(project)
        )
      end

      it 'returns nil if user cannot read release' do
        expect(release).to be_truthy
        expect(presenter.releases_anchor_data).to be_nil
      end

      context 'user not signed in' do
        let_it_be(:user) { nil }

        it 'returns nil if user is signed out' do
          expect(release).to be_truthy
          expect(presenter.releases_anchor_data).to be_nil
        end
      end
    end

    describe '#commits_anchor_data' do
      it 'returns commits data' do
        expect(presenter.commits_anchor_data).to have_attributes(
          is_link: true,
          label: a_string_including('0'),
          link: presenter.project_commits_path(project, project.repository.root_ref)
        )
      end
    end

    describe '#branches_anchor_data' do
      it 'returns branches data' do
        expect(presenter.branches_anchor_data).to have_attributes(
          is_link: true,
          label: a_string_including(project.repository.branches.size.to_s),
          link: presenter.project_branches_path(project)
        )
      end
    end

    describe '#terraform_states_anchor_data' do
      using RSpec::Parameterized::TableSyntax

      let(:anchor_goto_terraform) do
        have_attributes(
          is_link: true,
          label: a_string_including(project.terraform_states.size.to_s),
          link: presenter.project_terraform_index_path(project)
        )
      end

      where(:terraform_states_exists, :can_read_terraform_state, :expected_result) do
        true  | true  | ref(:anchor_goto_terraform)
        true  | false | nil
        false | true  | nil
        false | false | nil
      end

      with_them do
        before do
          allow(project.terraform_states).to receive(:exists?).and_return(terraform_states_exists)
          allow(presenter).to receive(:can?).with(user, :read_terraform_state,
            project).and_return(can_read_terraform_state)
        end

        it { expect(presenter.terraform_states_anchor_data).to match(expected_result) }
      end

      context 'terraform warning icon' do
        let(:label) { presenter.terraform_states_anchor_data.label }
        let(:title) do
          Regexp.quote(s_('Terraform|Support for periods (`.`) in Terraform state names might break existing states.'))
        end

        let(:expected) do
          %r{<span title="#{title}" class=".+" data-toggle="tooltip"><svg .+ data-testid="error-icon">.+</svg></span>}
        end

        it 'is present' do
          allow(project.terraform_states).to receive(:exists?).and_return(true)
          allow(presenter).to receive(:can?).with(user, :read_terraform_state, project).and_return(true)

          expect(label).to match(expected)
        end
      end
    end

    describe '#tags_anchor_data' do
      it 'returns tags data' do
        expect(presenter.tags_anchor_data).to have_attributes(
          is_link: true,
          label: a_string_including(project.repository.tags.size.to_s),
          link: presenter.project_tags_path(project)
        )
      end
    end

    describe '#new_file_anchor_data' do
      it 'returns new file data if user can push' do
        project.add_developer(user)

        expect(presenter.new_file_anchor_data).to have_attributes(
          is_link: false,
          label: a_string_including("New file"),
          link: presenter.project_new_blob_path(project, 'master')
        )
      end

      it 'returns nil if user cannot push' do
        expect(presenter.new_file_anchor_data).to be_nil
      end

      context 'when the project is empty' do
        let_it_be(:project) { create(:project, :empty_repo) }

        # Since we protect the default branch for empty repos
        it 'is empty for a developer' do
          project.add_developer(user)

          expect(presenter.new_file_anchor_data).to be_nil
        end
      end
    end

    describe '#readme_anchor_data' do
      context 'when user can push and README does not exists' do
        it 'returns anchor data' do
          project.add_developer(user)

          allow(project.repository).to receive(:readme_path).and_return(nil)

          expect(presenter.readme_anchor_data).to have_attributes(
            is_link: false,
            label: a_string_including('Add README'),
            link: presenter.add_readme_path
          )
        end
      end

      context 'when README exists' do
        it 'returns anchor data' do
          allow(project.repository).to receive(:readme_path).and_return('readme')

          expect(presenter.readme_anchor_data).to have_attributes(
            is_link: false,
            label: a_string_including('README'),
            link: presenter.readme_path
          )
        end
      end
    end

    describe '#changelog_anchor_data' do
      context 'when user can push and CHANGELOG does not exist' do
        it 'returns anchor data' do
          project.add_developer(user)

          allow(project.repository).to receive(:changelog).and_return(nil)

          expect(presenter.changelog_anchor_data).to have_attributes(
            is_link: false,
            label: a_string_including('Add CHANGELOG'),
            link: presenter.add_changelog_path
          )
        end
      end

      context 'when CHANGELOG exists' do
        it 'returns anchor data' do
          allow(project.repository).to receive(:changelog).and_return(double(name: 'foo'))

          expect(presenter.changelog_anchor_data).to have_attributes(
            is_link: false,
            label: a_string_including('CHANGELOG'),
            link: presenter.changelog_path
          )
        end
      end
    end

    describe '#license_anchor_data' do
      context 'when user can push and LICENSE does not exist' do
        it 'returns anchor data' do
          project.add_developer(user)

          allow(project.repository).to receive(:license_blob).and_return(nil)

          expect(presenter.license_anchor_data).to have_attributes(
            is_link: false,
            label: a_string_including('Add LICENSE'),
            link: presenter.add_license_path
          )
        end
      end

      context 'when LICENSE exists' do
        it 'returns anchor data' do
          allow(project.repository).to receive(:license_blob).and_return(double(name: 'foo'))

          expect(presenter.license_anchor_data).to have_attributes(
            is_link: false,
            label: a_string_including(presenter.license_short_name),
            link: presenter.license_path
          )
        end
      end
    end

    describe '#contribution_guide_anchor_data' do
      context 'when user can push and CONTRIBUTING does not exist' do
        it 'returns anchor data' do
          project.add_developer(user)

          allow(project.repository).to receive(:contribution_guide).and_return(nil)

          expect(presenter.contribution_guide_anchor_data).to have_attributes(
            is_link: false,
            label: a_string_including('Add CONTRIBUTING'),
            link: presenter.add_contribution_guide_path
          )
        end
      end

      context 'when CONTRIBUTING exists' do
        it 'returns anchor data' do
          allow(project.repository).to receive(:contribution_guide).and_return(double(name: 'foo'))

          expect(presenter.contribution_guide_anchor_data).to have_attributes(
            is_link: false,
            label: a_string_including('CONTRIBUTING'),
            link: presenter.contribution_guide_path
          )
        end
      end
    end

    describe '#autodevops_anchor_data' do
      it 'returns nil if builds feature is not available' do
        allow(project).to receive(:feature_available?).with(:builds, user).and_return(false)

        expect(presenter.autodevops_anchor_data).to be_nil
      end

      context 'when Auto Devops is enabled' do
        it 'returns anchor data' do
          allow(project).to receive(:auto_devops_enabled?).and_return(true)

          expect(presenter.autodevops_anchor_data).to have_attributes(
            is_link: false,
            label: a_string_including('Auto DevOps enabled'),
            link: nil
          )
        end
      end

      context 'when user can admin pipeline and CI yml does not exist' do
        it 'returns anchor data' do
          project.add_maintainer(user)

          allow(project).to receive(:auto_devops_enabled?).and_return(false)
          allow(project).to receive(:has_ci_config_file?).and_return(false)

          expect(presenter.autodevops_anchor_data).to have_attributes(
            is_link: false,
            label: a_string_including('Enable Auto DevOps'),
            link: presenter.project_settings_ci_cd_path(project, anchor: 'autodevops-settings')
          )
        end
      end
    end

    describe '#kubernetes_cluster_anchor_data' do
      context 'when user can create Kubernetes cluster' do
        it 'returns link to cluster if only one exists' do
          project.add_maintainer(user)

          cluster = create(:cluster, projects: [project])

          expect(presenter.kubernetes_cluster_anchor_data).to have_attributes(
            is_link: false,
            label: a_string_including('Kubernetes'),
            link: presenter.project_cluster_path(project, cluster)
          )
        end

        it 'returns link to clusters page if more than one exists' do
          project.add_maintainer(user)

          create(:cluster, :production_environment, projects: [project])
          create(:cluster, projects: [project])

          expect(presenter.kubernetes_cluster_anchor_data).to have_attributes(
            is_link: false,
            label: a_string_including('Kubernetes'),
            link: presenter.project_clusters_path(project)
          )
        end

        it 'returns link to create a cluster if no cluster exists' do
          project.add_maintainer(user)

          expect(presenter.kubernetes_cluster_anchor_data).to have_attributes(
            is_link: false,
            label: a_string_including('Add Kubernetes cluster'),
            link: presenter.project_clusters_path(project)
          )
        end
      end

      context 'when user cannot create Kubernetes cluster' do
        it 'returns nil' do
          expect(presenter.kubernetes_cluster_anchor_data).to be_nil
        end
      end
    end

    describe '#upload_anchor_data' do
      context 'when a user can push to the default branch' do
        before do
          project.add_developer(user)
        end

        it 'returns upload_anchor_data' do
          expect(presenter.upload_anchor_data).to have_attributes(
            is_link: false,
            label: a_string_including('Upload file'),
            data: {
              "can_push_code" => "true",
              "can_push_to_branch" => "true",
              "original_branch" => "master",
              "path" => "/#{project.full_path}/-/create/master",
              "project_path" => project.full_path,
              "target_branch" => "master",
              "full_name" => project.name_with_namespace
            }
          )
        end
      end

      context 'when the user cannot push to default branch' do
        it 'returns nil' do
          expect(presenter.upload_anchor_data).to be_nil
        end
      end
    end

    describe '#wiki_anchor_data' do
      using RSpec::Parameterized::TableSyntax

      let(:anchor_goto_wiki) do
        have_attributes(
          is_link: false,
          label: a_string_ending_with('Wiki'),
          link: wiki_path(project.wiki),
          class_modifier: 'btn-default'
        )
      end

      let(:anchor_add_wiki) do
        have_attributes(
          is_link: false,
          label: a_string_ending_with('Add Wiki'),
          link: "#{wiki_path(project.wiki)}?view=create"
        )
      end

      where(:wiki_enabled, :can_read_wiki, :has_home_page, :can_create_wiki, :expected_result) do
        true  | true  | true  | true  | ref(:anchor_goto_wiki)
        true  | true  | true  | false | ref(:anchor_goto_wiki)
        true  | true  | false | true  | ref(:anchor_add_wiki)
        true  | true  | false | false | nil
        true  | false | true  | true  | nil
        true  | false | true  | false | nil
        true  | false | false | true  | nil
        true  | false | false | false | nil
        false | true  | true  | true  | nil
        false | true  | true  | false | nil
        false | true  | true  | false | nil
        false | true  | false | true  | nil
        false | true  | false | false | nil
        false | false | true  | true  | nil
        false | false | true  | false | nil
        false | false | false | true  | nil
        false | false | false | false | nil
      end

      with_them do
        before do
          allow(project).to receive(:wiki_enabled?).and_return(wiki_enabled)
          allow(presenter).to receive(:can?).with(user, :read_wiki, project).and_return(can_read_wiki)
          allow(project.wiki).to receive(:has_home_page?).and_return(has_home_page)
          allow(presenter).to receive(:can?).with(user, :create_wiki, project).and_return(can_create_wiki)
        end

        it { expect(presenter.wiki_anchor_data).to match(expected_result) }
      end
    end

    describe '#pages_anchor_data' do
      using RSpec::Parameterized::TableSyntax

      let(:anchor_goto_pages) do
        have_attributes(
          is_link: false,
          label: a_string_ending_with('GitLab Pages'),
          link: Gitlab::Pages::UrlBuilder
          .new(project)
          .pages_url,
          class_modifier: 'btn-default'
        )
      end

      where(:pages_deployed, :read_pages_content, :expected_result) do
        true  | true  | ref(:anchor_goto_pages)
        true  | false | nil
        false | true  | nil
        false | false | nil
      end

      with_them do
        before do
          allow(project).to receive(:pages_deployed?).and_return(pages_deployed)
          allow(presenter).to receive(:can?).with(user, :read_pages_content,
            project).and_return(read_pages_content)
        end

        it { expect(presenter.pages_anchor_data).to match(expected_result) }
      end
    end
  end

  describe '#statistics_buttons' do
    let(:project) { build_stubbed(:project) }

    it 'orders the items correctly' do
      allow(project.repository).to receive(:readme_path).and_return('readme')
      allow(project.repository).to receive(:license_blob).and_return(nil)
      allow(project.repository).to receive(:changelog).and_return(nil)
      allow(project.repository).to receive(:contribution_guide).and_return(double(name: 'foo'))
      allow(presenter).to receive(:filename_path).and_return('fake/path')
      allow(presenter).to receive(:contribution_guide_path).and_return('fake_path')

      buttons = presenter.statistics_buttons(show_auto_devops_callout: false)
      expect(buttons.map(&:label)).to start_with(
        a_string_including('README'),
        a_string_including('CONTRIBUTING')
      )
    end
  end

  describe '#repo_statistics_buttons' do
    subject(:empty_repo_statistics_buttons) { presenter.empty_repo_statistics_buttons }

    before do
      allow(project).to receive(:auto_devops_enabled?).and_return(false)
    end

    context 'empty repo' do
      let(:project) { create(:project, :stubbed_repository) }

      it 'includes a button to configure integrations for maintainers' do
        project.add_maintainer(user)

        expect(empty_repo_statistics_buttons.map(&:label)).to include(
          a_string_including('Configure Integration')
        )
      end

      it 'does not include a button if not a maintainer' do
        expect(empty_repo_statistics_buttons.map(&:label)).not_to include(
          a_string_including('Configure Integration')
        )
      end

      context 'for a developer' do
        before do
          project.add_developer(user)
        end

        it 'orders the items correctly' do
          expect(empty_repo_statistics_buttons.map(&:label)).to start_with(
            a_string_including('Upload'),
            a_string_including('New'),
            a_string_including('README'),
            a_string_including('LICENSE'),
            a_string_including('CHANGELOG'),
            a_string_including('CONTRIBUTING'),
            a_string_including('CI/CD')
          )
        end
      end
    end

    context 'initialized repo' do
      let_it_be(:project) { create(:project, :repository) }

      it 'orders the items correctly' do
        expect(empty_repo_statistics_buttons.map(&:label)).to start_with(
          a_string_including('README'),
          a_string_including('License'),
          a_string_including('CHANGELOG'),
          a_string_including('CONTRIBUTING')
        )
      end
    end
  end

  describe '#can_setup_review_app?' do
    subject { presenter.can_setup_review_app? }

    context 'when the ci/cd file is missing' do
      before do
        allow(presenter).to receive(:cicd_missing?).and_return(true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when the ci/cd file is not missing' do
      before do
        allow(presenter).to receive(:cicd_missing?).and_return(false)
      end

      context 'and the user can create a cluster' do
        before do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(user, :create_cluster, project).and_return(true)
        end

        context 'and there is no cluster associated to this project' do
          let(:project) { create(:project, clusters: []) }

          it { is_expected.to be_truthy }
        end

        context 'and there is already a cluster associated to this project' do
          let(:project) { create(:project, clusters: [build(:cluster, :providing_by_gcp)]) }

          it { is_expected.to be_falsey }
        end

        context 'when a group cluster is instantiated' do
          let_it_be(:cluster) { create(:cluster, :group) }
          let_it_be(:group) { cluster.group }

          context 'and the project belongs to this group' do
            let!(:project) { create(:project, group: group) }

            it { is_expected.to be_falsey }
          end

          context 'and the project does not belong to this group' do
            it { is_expected.to be_truthy }
          end
        end

        context 'and there is already an instance cluster' do
          it 'is false' do
            create(:cluster, :instance)

            is_expected.to be_falsey
          end
        end
      end

      context 'and the user cannot create a cluster' do
        before do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(user, :create_cluster, project).and_return(false)
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#has_review_app?' do
    subject { presenter.has_review_app? }

    let_it_be(:project) { create(:project, :repository) }

    context 'when review apps exist' do
      let!(:environment) do
        create(:environment, :with_review_app, project: project)
      end

      it { is_expected.to be_truthy }
    end

    context 'when review apps do not exist' do
      let!(:environment) do
        create(:environment, project: project)
      end

      it { is_expected.to be_falsey }
    end
  end
end
