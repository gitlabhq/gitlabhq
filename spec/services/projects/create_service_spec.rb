# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CreateService, '#execute', feature_category: :groups_and_projects do
  include ExternalAuthorizationServiceHelpers

  let_it_be(:user) { create(:user) }
  let(:project_name) { 'GitLab' }
  let(:opts) do
    {
      name: project_name,
      namespace_id: user.namespace.id
    }
  end

  context 'with labels' do
    subject(:project) { create_project(user, opts) }

    before_all do
      Label.create!(title: 'bug', template: true)
    end

    it 'creates labels on project creation' do
      expect(project.labels).to include have_attributes(
        type: eq('ProjectLabel'),
        project_id: eq(project.id),
        title: eq('bug')
      )
    end

    context 'using gitlab project import' do
      before do
        opts[:import_type] = 'gitlab_project'
      end

      it 'does not creates labels on project creation' do
        expect(project.labels.size).to eq(0)
      end
    end
  end

  describe 'setting name and path' do
    subject(:project) { create_project(user, opts) }

    context 'when both are set' do
      let(:opts) { { name: 'one', path: 'two' } }

      it 'keeps them as specified' do
        expect(project.name).to eq('one')
        expect(project.path).to eq('two')
        expect(project.project_namespace).to be_in_sync_with_project(project)
      end
    end

    context 'when path is set' do
      let(:opts) { { path: 'one.two_three-four' } }

      it 'sets name == path' do
        expect(project.path).to eq('one.two_three-four')
        expect(project.name).to eq(project.path)
        expect(project.project_namespace).to be_in_sync_with_project(project)
      end
    end

    context 'when name is a valid path' do
      let(:opts) { { name: 'one.two_three-four' } }

      it 'sets path == name' do
        expect(project.name).to eq('one.two_three-four')
        expect(project.path).to eq(project.name)
        expect(project.project_namespace).to be_in_sync_with_project(project)
      end
    end

    context 'when name is not a valid path' do
      let(:opts) { { name: 'one.two_three-four and five' } }

      # TODO: Retained for backwards compatibility. Remove in API v5.
      #       See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/52725
      it 'parameterizes the name' do
        expect(project.name).to eq('one.two_three-four and five')
        expect(project.path).to eq('one-two_three-four-and-five')
        expect(project.project_namespace).to be_in_sync_with_project(project)
      end
    end
  end

  describe 'setting organization' do
    subject(:project) { create_project(user, opts) }

    context 'with group namespace' do
      let_it_be(:namespace) { create(:group) }

      before do
        opts[:namespace_id] = namespace.id
      end

      it 'sets correct organization' do
        expect(project.organization).to eq(namespace.organization)
      end
    end

    context 'with user namespace' do
      it 'sets correct organization' do
        expect(project.organization).to eq(user.namespace.organization)
      end
    end
  end

  describe 'topics' do
    subject(:project) { create_project(user, opts) }

    context "with 'topics' parameter" do
      let(:opts) { { name: 'topic-project', topics: 'topics' } }

      it 'keeps them as specified' do
        expect(project.topic_list).to eq(%w[topics])
      end
    end

    context "with 'topic_list' parameter" do
      let(:opts) { { name: 'topic-project', topic_list: 'topic_list' } }

      it 'keeps them as specified' do
        expect(project.topic_list).to eq(%w[topic_list])
      end
    end

    context "with 'tag_list' parameter (deprecated)" do
      let(:opts) { { name: 'topic-project', tag_list: 'tag_list' } }

      it 'keeps them as specified' do
        expect(project.topic_list).to eq(%w[tag_list])
      end
    end
  end

  context 'user namespace' do
    it 'creates a project in user namespace' do
      project = create_project(user, opts)

      expect(project).to be_valid
      expect(project.first_owner).to eq(user)
      expect(project.team.maintainers).not_to include(user)
      expect(project.team.owners).to contain_exactly(user)
      expect(project.namespace).to eq(user.namespace)
      expect(project.project_namespace).to be_in_sync_with_project(project)
    end

    context 'project_authorizations record creation' do
      context 'when the project_authrizations records are not created via the callback' do
        it 'still creates project_authrizations record for the user' do
          # stub out the callback that creates project_authorizations records on the `ProjectMember` model.
          expect_next_instance_of(ProjectMember) do |member|
            expect(member).to receive(:refresh_member_authorized_projects).and_return(nil)
          end

          project = create_project(user, opts)

          expected_record = project.project_authorizations.where(
            user: user,
            access_level: ProjectMember::OWNER
          )

          expect(expected_record).to exist
        end
      end
    end

    context 'when the passed in namespace is for a bot user' do
      let(:bot_user) { create(:user, :project_bot) }
      let(:opts) do
        { name: project_name, namespace_id: bot_user.namespace.id }
      end

      it 'raises an error' do
        project = create_project(bot_user, opts)

        expect(project.errors.errors.length).to eq 1
        expect(project.errors.messages[:namespace].first).to eq("is not valid")
      end
    end
  end

  describe 'after create actions' do
    it 'invalidate personal_projects_count caches' do
      expect(Rails.cache).to receive(:delete).with(['users', user.id, 'personal_projects_count'])

      create_project(user, opts)
    end

    it 'creates associated project settings' do
      project = create_project(user, opts)

      expect(project.project_setting).to be_persisted
    end

    it_behaves_like 'storing arguments in the application context' do
      let(:expected_params) { { project: subject.full_path } }

      subject { create_project(user, opts) }
    end

    it 'logs creation' do
      allow(Gitlab::AppLogger).to receive(:info)

      expect(Gitlab::AppLogger).to receive(:info).with(/#{user.name} created a new project/)

      create_project(user, opts)
    end

    it 'publishes a ProjectCreatedEvent' do
      group = create(:group, :nested).tap do |group|
        group.add_owner(user)
      end

      expect { create_project(user, name: 'Project', path: 'project', namespace_id: group.id) }
        .to publish_event(Projects::ProjectCreatedEvent)
        .with(
          project_id: kind_of(Numeric),
          namespace_id: group.id,
          root_namespace_id: group.parent_id
        )
    end
  end

  context "admin creates project with other user's namespace_id" do
    context 'when admin mode is enabled', :enable_admin_mode do
      it 'sets the correct permissions' do
        admin = create(:admin)
        project = create_project(admin, opts)

        expect(project).to be_persisted
        expect(project.owner).to eq(user)
        expect(project.first_owner).to eq(user)
        expect(project.team.owners).to contain_exactly(user)
        expect(project.namespace).to eq(user.namespace)
        expect(project.project_namespace).to be_in_sync_with_project(project)
      end
    end

    context 'when admin mode is disabled' do
      it 'is not allowed' do
        admin = create(:admin)
        project = create_project(admin, opts)

        expect(project).not_to be_persisted
        expect(project.project_namespace).to be_in_sync_with_project(project)
      end
    end
  end

  context 'group namespace' do
    let(:group) do
      create(:group).tap do |group|
        group.add_owner(user)
      end
    end

    before do
      user.refresh_authorized_projects # Ensure cache is warm
    end

    subject(:project) { create_project(user, opts.merge!(namespace_id: group.id)) }

    shared_examples 'has sync-ed traversal_ids' do
      specify { expect(project.reload.project_namespace.traversal_ids).to eq([project.namespace.traversal_ids, project.project_namespace.id].flatten.compact) }
    end

    it 'creates the project' do
      expect(project).to be_valid
      expect(project.owner).to eq(group)
      expect(project.namespace).to eq(group)
      expect(project.team.owners).to include(user)
      expect(user.authorized_projects).to include(project)
      expect(project.project_namespace).to be_in_sync_with_project(project)
    end

    it_behaves_like 'has sync-ed traversal_ids'

    context 'when user is not allowed to create projects' do
      it 'does not create the project' do
        maintainer_group =
          create(:group, project_creation_level: Gitlab::Access::OWNER_PROJECT_ACCESS) do |group|
            group.add_maintainer(user)
          end
        project = create_project(user, opts.merge!(namespace_id: maintainer_group.id))

        expect(project).not_to be_persisted
        expect(project.errors.messages[:namespace].first).to eq('is not valid')
      end
    end

    context 'when project is an import' do
      let(:group) do
        create(:group).tap do |group|
          group.add_developer(user)
        end
      end

      context 'and import is from a built-in template' do
        let(:project_template) { Gitlab::ProjectTemplate.find(:rails) }

        it 'does create the project' do
          project = create_project(user, opts.merge!(template_name: project_template.name))

          expect(project).to be_persisted
          expect(project.errors).to be_blank
        end
      end

      context 'and import is from a sample template' do
        let(:sample_template) { Gitlab::SampleDataTemplate.find(:sample) }

        it 'does create the project' do
          project = create_project(user, opts.merge!(template_name: sample_template.name))

          expect(project).to be_persisted
          expect(project.errors).to be_blank
        end
      end

      context 'when user is not allowed to import projects' do
        before do
          stub_application_setting(import_sources: ['gitlab_project_migration'])
        end

        it 'does not create the project' do
          project = create_project(user, opts.merge!(namespace_id: group.id, import_type: 'gitlab_project_migration'))

          expect(project).not_to be_persisted
          expect(project.errors.messages[:user].first).to eq('is not allowed to import projects')
        end
      end
    end
  end

  context 'group sharing', :sidekiq_inline do
    let_it_be(:group) { create(:group) }
    let_it_be(:shared_group) { create(:group) }
    let_it_be(:shared_group_user) { create(:user) }

    let(:opts) do
      {
        name: project_name,
        namespace_id: shared_group.id
      }
    end

    before do
      create(:group_group_link, shared_group: shared_group, shared_with_group: group)

      shared_group.add_maintainer(shared_group_user)
      group.add_developer(user)
    end

    it 'updates authorization' do
      shared_group_project = create_project(shared_group_user, opts)

      expect(
        Ability.allowed?(shared_group_user, :read_project, shared_group_project)
      ).to be_truthy
      expect(
        Ability.allowed?(user, :read_project, shared_group_project)
      ).to be_truthy
    end
  end

  context 'user with project limit' do
    let_it_be(:user_with_projects_limit) { create(:user, projects_limit: 0) }

    let(:params) { opts.merge!(namespace_id: target_namespace.id) }

    subject(:project) { create_project(user_with_projects_limit, params) }

    context 'under personal namespace' do
      let(:target_namespace) { user_with_projects_limit.namespace }

      it 'cannot create a project' do
        expect(project.errors.errors.length).to eq 1
        expect(project.errors.messages[:limit_reached].first).to eq(_('You cannot create projects in your personal namespace. Contact your GitLab administrator.'))
      end
    end

    context 'under group namespace' do
      let_it_be(:group) do
        create(:group).tap do |group|
          group.add_owner(user_with_projects_limit)
        end
      end

      let(:target_namespace) { group }

      it 'can create a project' do
        expect(project).to be_valid
        expect(project).to be_saved
        expect(project.errors.errors.length).to eq 0
      end
    end
  end

  context 'membership overrides', :sidekiq_inline do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:subgroup_for_projects) { create(:group, :private, parent: group) }
    let_it_be(:subgroup_for_access) { create(:group, :private, parent: group) }
    let_it_be(:group_maintainer) { create(:user) }

    let(:group_access_level) { Gitlab::Access::REPORTER }
    let(:subgroup_access_level) { Gitlab::Access::DEVELOPER }
    let(:share_max_access_level) { Gitlab::Access::MAINTAINER }
    let(:opts) do
      {
        name: project_name,
        namespace_id: subgroup_for_projects.id
      }
    end

    before do
      group.add_maintainer(group_maintainer)

      create(
        :group_group_link,
        shared_group: subgroup_for_projects,
        shared_with_group: subgroup_for_access,
        group_access: share_max_access_level
      )
    end

    context 'membership is higher from group hierarchy' do
      let(:group_access_level) { Gitlab::Access::MAINTAINER }

      it 'updates authorization' do
        create(:group_member, access_level: subgroup_access_level, group: subgroup_for_access, user: user)
        create(:group_member, access_level: group_access_level, group: group, user: user)

        subgroup_project = create_project(group_maintainer, opts)

        project_authorization = ProjectAuthorization.where(
          project_id: subgroup_project.id,
          user_id: user.id,
          access_level: group_access_level)

        expect(project_authorization).to exist
      end
    end

    context 'membership is higher from group share' do
      let(:subgroup_access_level) { Gitlab::Access::MAINTAINER }

      context 'share max access level is not limiting' do
        it 'updates authorization' do
          create(:group_member, access_level: group_access_level, group: group, user: user)
          create(:group_member, access_level: subgroup_access_level, group: subgroup_for_access, user: user)

          subgroup_project = create_project(group_maintainer, opts)

          project_authorization = ProjectAuthorization.where(
            project_id: subgroup_project.id,
            user_id: user.id,
            access_level: subgroup_access_level)

          expect(project_authorization).to exist
        end
      end

      context 'share max access level is limiting' do
        let(:share_max_access_level) { Gitlab::Access::DEVELOPER }

        it 'updates authorization' do
          create(:group_member, access_level: group_access_level, group: group, user: user)
          create(:group_member, access_level: subgroup_access_level, group: subgroup_for_access, user: user)

          subgroup_project = create_project(group_maintainer, opts)

          project_authorization = ProjectAuthorization.where(
            project_id: subgroup_project.id,
            user_id: user.id,
            access_level: share_max_access_level)

          expect(project_authorization).to exist
        end
      end
    end
  end

  context 'error handling' do
    it 'handles invalid options' do
      opts[:invalid] = 'option'
      expect(create_project(user, opts)).to eq(nil)
    end
  end

  context 'wiki_enabled creates repository directory' do
    context 'wiki_enabled true creates wiki repository directory' do
      it do
        project = create_project(user, opts)

        expect(wiki_repo(project).exists?).to be_truthy
      end
    end

    context 'wiki_enabled false does not create wiki repository directory' do
      it do
        opts[:wiki_enabled] = false
        project = create_project(user, opts)

        expect(wiki_repo(project).exists?).to be_falsey
      end
    end

    def wiki_repo(project)
      relative_path = ProjectWiki.new(project).disk_path + '.git'
      Gitlab::Git::Repository.new(project.repository_storage, relative_path, 'foobar', project.full_path)
    end
  end

  context 'import data' do
    let(:import_data) { { data: { 'test' => 'some data' } } }
    let(:imported_project) { create_project(user, { name: 'test', import_url: 'http://import-url', import_data: import_data }) }

    it 'does not write repository config' do
      imported_project
      expect(imported_project.project_namespace).to be_in_sync_with_project(imported_project)
    end

    it 'stores import data and URL' do
      expect(imported_project.import_data).to be_persisted
      expect(imported_project.import_data.data).to eq(import_data[:data])
      expect(imported_project.import_url).to eq('http://import-url')
    end

    it 'tracks for imported project' do
      imported_project

      expect_snowplow_event(category: described_class.name, action: 'import_project', user: user)
    end

    describe 'import scheduling' do
      context 'when project import type is gitlab project migration' do
        it 'does not schedule project import' do
          opts[:import_type] = 'gitlab_project_migration'

          project = create_project(user, opts)

          expect(project.import_state.status).to eq('none')
        end
      end
    end
  end

  context 'builds_enabled global setting' do
    let(:project) { create_project(user, opts) }

    subject { project.builds_enabled? }

    context 'global builds_enabled false does not enable CI by default' do
      before do
        project.project_feature.update_attribute(:builds_access_level, ProjectFeature::DISABLED)
      end

      it { is_expected.to be_falsey }
    end

    context 'global builds_enabled true does enable CI by default' do
      it { is_expected.to be_truthy }
    end
  end

  context 'default visibility level' do
    let(:group) { create(:group, :private) }

    using RSpec::Parameterized::TableSyntax

    where(:case_name, :group_level, :project_level) do
      [
        ['in public group',   Gitlab::VisibilityLevel::PUBLIC,   Gitlab::VisibilityLevel::INTERNAL],
        ['in internal group', Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::INTERNAL],
        ['in private group',  Gitlab::VisibilityLevel::PRIVATE,  Gitlab::VisibilityLevel::PRIVATE]
      ]
    end

    with_them do
      before do
        stub_application_setting(default_project_visibility: Gitlab::VisibilityLevel::INTERNAL)
        group.add_developer(user)
        group.update!(visibility_level: group_level)

        opts.merge!(
          name: 'test',
          namespace: group,
          path: 'foo'
        )
      end

      it 'creates project with correct visibility level', :aggregate_failures do
        project = create_project(user, opts)

        expect(project).to respond_to(:errors)
        expect(project.errors).to be_blank
        expect(project.visibility_level).to eq(project_level)
        expect(project).to be_saved
        expect(project).to be_valid
        expect(project.project_namespace).to be_in_sync_with_project(project)
      end
    end
  end

  context 'restricted visibility level' do
    before do
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
    end

    shared_examples 'restricted visibility' do
      it 'does not allow a restricted visibility level for non-admins' do
        project = create_project(user, opts)

        expect(project).to respond_to(:errors)
        expect(project.errors.messages).to have_key(:visibility_level)
        expect(project.errors.messages[:visibility_level].first).to(
          match('restricted by your GitLab administrator')
        )
        expect(project.project_namespace).to be_in_sync_with_project(project)
      end

      it 'does not allow a restricted visibility level for admins when admin mode is disabled' do
        admin = create(:admin)
        project = create_project(admin, opts)

        expect(project.errors.any?).to be(true)
        expect(project.saved?).to be_falsey
      end

      it 'allows a restricted visibility level for admins when admin mode is enabled', :enable_admin_mode do
        admin = create(:admin)
        project = create_project(admin, opts)

        expect(project.errors.any?).to be(false)
        expect(project.saved?).to be(true)
      end
    end

    context 'when visibility is project based' do
      before do
        opts.merge!(
          visibility_level: Gitlab::VisibilityLevel::PUBLIC
        )
      end

      include_examples 'restricted visibility'
    end

    context 'when visibility is overridden' do
      let(:visibility) { 'public' }

      before do
        opts.merge!(
          import_data: {
            data: {
              override_params: {
                visibility: visibility
              }
            }
          }
        )
      end

      include_examples 'restricted visibility'

      context 'when visibility is misspelled' do
        let(:visibility) { 'publik' }

        it 'does not restrict project creation' do
          project = create_project(user, opts)

          expect(project.errors.any?).to be(false)
          expect(project.saved?).to be(true)
        end
      end
    end
  end

  context 'repository creation' do
    it 'synchronously creates the repository' do
      expect_next_instance_of(Project) do |instance|
        expect(instance).to receive(:create_repository).and_return(true)
      end

      project = create_project(user, opts)

      expect(project).to be_valid
      expect(project).to be_persisted
      expect(project.owner).to eq(user)
      expect(project.namespace).to eq(user.namespace)
      expect(project.project_namespace).to be_in_sync_with_project(project)
    end

    it 'raises when repository fails to create' do
      expect_next_instance_of(Project) do |instance|
        expect(instance).to receive(:create_repository).and_return(false)
      end

      project = create_project(user, opts)
      expect(project).not_to be_persisted
      expect(project.errors.messages).to have_key(:base)
      expect(project.errors.messages[:base].first).to match('Failed to create repository')
    end

    context 'when another repository already exists on disk' do
      let(:opts) do
        {
          name: 'existing',
          namespace_id: user.namespace.id
        }
      end

      context 'with legacy storage' do
        let(:raw_fake_repo) { Gitlab::Git::Repository.new('default', File.join(user.namespace.full_path, 'existing.git'), nil, nil) }

        before do
          stub_application_setting(hashed_storage_enabled: false)
          raw_fake_repo.create_repository
        end

        after do
          raw_fake_repo.remove
        end

        it 'does not allow to create a project when path matches existing repository on disk' do
          project = create_project(user, opts)

          expect(project).not_to be_persisted
          expect(project).to respond_to(:errors)
          expect(project.errors.messages).to have_key(:base)
          expect(project.errors.messages[:base].first).to match('There is already a repository with that name on disk')
          expect(project.project_namespace).to be_in_sync_with_project(project)
        end

        it 'does not allow to import project when path matches existing repository on disk' do
          project = create_project(user, opts.merge({ import_url: 'https://gitlab.com/gitlab-org/gitlab-test.git' }))

          expect(project).not_to be_persisted
          expect(project).to respond_to(:errors)
          expect(project.errors.messages).to have_key(:base)
          expect(project.errors.messages[:base].first).to match('There is already a repository with that name on disk')
          expect(project.project_namespace).to be_in_sync_with_project(project)
        end
      end

      context 'with hashed storage' do
        let(:hash) { '6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b' }
        let(:hashed_path) { '@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b' }
        let(:raw_fake_repo) { Gitlab::Git::Repository.new('default', "#{hashed_path}.git", nil, nil) }

        before do
          allow(Digest::SHA2).to receive(:hexdigest) { hash }

          begin
            raw_fake_repo.create_repository
          rescue Gitlab::Git::Repository::RepositoryExists
            # Likely, a previous project record with id=1 had its repository created,
            # but the repository was not cleaned up properly.
            #
            # So we can do nothing for now.
          end
        end

        after do
          raw_fake_repo.remove
        end

        it 'does not allow to create a project when path matches existing repository on disk' do
          project = create_project(user, opts)

          expect(project).not_to be_persisted
          expect(project).to respond_to(:errors)
          expect(project.errors.messages).to have_key(:base)
          expect(project.errors.messages[:base].first).to match('There is already a repository with that name on disk')
          expect(project.project_namespace).to be_in_sync_with_project(project)
        end
      end
    end
  end

  context 'when readme initialization is requested' do
    let(:project) { create_project(user, opts) }

    before do
      opts[:initialize_with_readme] = '1'
    end

    shared_examples 'a repo with a README.md' do
      it { expect(project.repository.commit_count).to be(1) }
      it { expect(project.repository.readme.name).to eql('README.md') }
      it { expect(project.repository.readme.data).to include(expected_content) }
    end

    it_behaves_like 'a repo with a README.md' do
      let(:expected_content) do
        <<~MARKDOWN
          cd existing_repo
          git remote add origin #{project.http_url_to_repo}
          git branch -M master
          git push -uf origin master
        MARKDOWN
      end
    end

    context 'and a readme_template is specified' do
      before do
        opts[:readme_template] = "# GitLab\nThis is customized readme."
      end

      it_behaves_like 'a repo with a README.md' do
        let(:expected_content) { "# GitLab\nThis is customized readme." }
      end
    end

    context 'and default_branch is specified' do
      before do
        opts[:default_branch] = 'example_branch'
      end

      it 'creates the correct branch' do
        expect(project.repository.branch_names).to contain_exactly('example_branch')
      end

      it_behaves_like 'a repo with a README.md' do
        let(:expected_content) do
          <<~MARKDOWN
            cd existing_repo
            git remote add origin #{project.http_url_to_repo}
            git branch -M example_branch
            git push -uf origin example_branch
          MARKDOWN
        end
      end
    end

    context 'and the default branch setting is configured' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:default_branch_name).and_return('example_branch')
      end

      it 'creates the correct branch' do
        expect(project.repository.branch_names).to contain_exactly('example_branch')
      end

      it_behaves_like 'a repo with a README.md' do
        let(:expected_content) do
          <<~MARKDOWN
            cd existing_repo
            git remote add origin #{project.http_url_to_repo}
            git branch -M example_branch
            git push -uf origin example_branch
          MARKDOWN
        end
      end
    end
  end

  context 'when SAST initialization is requested' do
    let(:project) { create_project(user, opts) }

    before do
      opts[:initialize_with_sast] = '1'
      allow(Gitlab::CurrentSettings).to receive(:default_branch_name).and_return('main')
    end

    it 'creates a commit for SAST', :aggregate_failures do
      expect(project.repository.commit_count).to be(1)
      expect(project.repository.commit.message).to eq(
        'Configure SAST in `.gitlab-ci.yml`, creating this file if it does not already exist'
      )
    end
  end

  context 'when SHA256 format is requested' do
    let(:project) { create_project(user, opts) }
    let(:opts) { super().merge(initialize_with_readme: true, repository_object_format: 'sha256') }

    before do
      allow(Gitlab::CurrentSettings).to receive(:default_branch_name).and_return('main')
    end

    it 'creates a repository with SHA256 commit hashes', :aggregate_failures do
      expect(project.repository.commit_count).to be(1)
      expect(project.project_repository.object_format).to eq 'sha256'
      expect(project.commit.id.size).to eq 64
    end

    context 'when "support_sha256_repositories" feature flag is disabled' do
      before do
        stub_feature_flags(support_sha256_repositories: false)
      end

      it 'creates a repository with default SHA1 commit hash' do
        expect(project.repository.commit_count).to be(1)
        expect(project.project_repository.object_format).to eq 'sha1'
        expect(project.commit.id.size).to eq 40
      end
    end
  end

  describe 'create integration for the project' do
    subject(:project) { create_project(user, opts) }

    context 'when an instance-level instance specific integration' do
      let!(:instance_specific_integration) { create(:beyond_identity_integration) }

      it 'creates integration inheriting from the instance level integration' do
        expect(project.integrations.count).to eq(1)
        expect(project.integrations.first.active).to eq(instance_specific_integration.active)
        expect(project.integrations.first.inherit_from_id).to eq(instance_specific_integration.id)
      end

      context 'when there is a group-level exclusion' do
        let(:opts) do
          {
            name: project_name,
            namespace_id: group.id
          }
        end

        let!(:group) do
          create(:group).tap do |group|
            group.add_owner(user)
          end
        end

        let!(:group_integration) do
          create(:beyond_identity_integration, group: group, instance: false, active: false)
        end

        it 'creates a service from the group-level integration' do
          expect(project.integrations.count).to eq(1)
          expect(project.integrations.first.active).to eq(group_integration.active)
          expect(project.integrations.first.inherit_from_id).to eq(group_integration.id)
        end
      end
    end

    context 'with an active instance-level integration' do
      let!(:instance_integration) { create(:prometheus_integration, :instance, api_url: 'https://prometheus.instance.com/') }

      it 'creates an integration from the instance-level integration' do
        expect(project.integrations.count).to eq(1)
        expect(project.integrations.first.api_url).to eq(instance_integration.api_url)
        expect(project.integrations.first.inherit_from_id).to eq(instance_integration.id)
      end

      context 'with an active group-level integration' do
        let!(:group_integration) { create(:prometheus_integration, :group, group: group, api_url: 'https://prometheus.group.com/') }
        let!(:group) do
          create(:group).tap do |group|
            group.add_owner(user)
          end
        end

        let(:opts) do
          {
            name: project_name,
            namespace_id: group.id
          }
        end

        it 'creates an integration from the group-level integration' do
          expect(project.integrations.count).to eq(1)
          expect(project.integrations.first.api_url).to eq(group_integration.api_url)
          expect(project.integrations.first.inherit_from_id).to eq(group_integration.id)
        end

        context 'with an active subgroup' do
          let!(:subgroup_integration) { create(:prometheus_integration, :group, group: subgroup, api_url: 'https://prometheus.subgroup.com/') }
          let!(:subgroup) do
            create(:group, parent: group).tap do |subgroup|
              subgroup.add_owner(user)
            end
          end

          let(:opts) do
            {
              name: project_name,
              namespace_id: subgroup.id
            }
          end

          it 'creates an integration from the subgroup-level integration' do
            expect(project.integrations.count).to eq(1)
            expect(project.integrations.first.api_url).to eq(subgroup_integration.api_url)
            expect(project.integrations.first.inherit_from_id).to eq(subgroup_integration.id)
          end
        end
      end
    end
  end

  context 'when skip_disk_validation is used' do
    it 'sets the project attribute' do
      opts[:skip_disk_validation] = true
      project = create_project(user, opts)

      expect(project.skip_disk_validation).to be_truthy
    end
  end

  it 'calls the passed block' do
    fake_block = double('block')
    opts[:relations_block] = fake_block

    expect_next_instance_of(Project) do |project|
      expect(fake_block).to receive(:call).with(project)
    end

    create_project(user, opts)
  end

  it 'writes project full path to gitaly' do
    project = create_project(user, opts)

    expect(project.repository.full_path).to eq project.full_path
  end

  it 'triggers PostCreationWorker' do
    expect(Projects::PostCreationWorker).to receive(:perform_async).with(a_kind_of(Integer))

    create_project(user, opts)
  end

  context 'when import source is enabled' do
    before do
      stub_application_setting(import_sources: ['github'])
    end

    it 'does not raise an error when import_source is string' do
      opts[:import_type] = 'github'

      project = create_project(user, opts)

      expect(project).to be_persisted
      expect(project.errors).to be_blank
    end

    it 'does not raise an error when import_source is symbol' do
      opts[:import_type] = :github

      project = create_project(user, opts)

      expect(project).to be_persisted
      expect(project.errors).to be_blank
    end
  end

  context 'when import source is disabled' do
    before do
      stub_application_setting(import_sources: [])
      opts[:import_type] = 'git'
    end

    it 'raises an error' do
      project = create_project(user, opts)

      expect(project).to respond_to(:errors)
      expect(project.errors).to have_key(:import_source_disabled)
      expect(project.saved?).to be_falsey
    end
  end

  context 'when github import source is disabled' do
    before do
      stub_application_setting(import_sources: [])
      opts[:import_type] = 'github'
    end

    it 'does not create the project' do
      project = create_project(user, opts)

      expect(project.errors[:import_source_disabled]).to include('github import source is disabled')
      expect(project).not_to be_persisted
    end
  end

  context 'when bitbucket server import source is disabled' do
    before do
      stub_application_setting(import_sources: [])
      opts[:import_type] = 'bitbucket_server'
    end

    it 'does not create the project' do
      project = create_project(user, opts)

      expect(project.errors[:import_source_disabled]).to include('bitbucket_server import source is disabled')
      expect(project).not_to be_persisted
    end
  end

  context 'with external authorization enabled' do
    before do
      enable_external_authorization_service_check
    end

    it 'does not save the project with an error if the service denies access' do
      expect(::Gitlab::ExternalAuthorization)
        .to receive(:access_allowed?).with(user, 'new-label', any_args) { false }

      project = create_project(user, opts.merge({ external_authorization_classification_label: 'new-label' }))

      expect(project.errors[:external_authorization_classification_label]).to be_present
      expect(project).not_to be_persisted
    end

    it 'saves the project when the user has access to the label' do
      expect(::Gitlab::ExternalAuthorization)
        .to receive(:access_allowed?).with(user, 'new-label', any_args) { true }.at_least(1).time

      project = create_project(user, opts.merge({ external_authorization_classification_label: 'new-label' }))

      expect(project).to be_persisted
      expect(project.external_authorization_classification_label).to eq('new-label')
    end

    it 'does not save the project when the user has no access to the default label and no label is provided' do
      expect(::Gitlab::ExternalAuthorization)
        .to receive(:access_allowed?).with(user, 'default_label', any_args) { false }

      project = create_project(user, opts)

      expect(project.errors[:external_authorization_classification_label]).to be_present
      expect(project).not_to be_persisted
    end
  end

  context 'with specialized project_authorization workers' do
    let_it_be(:other_user) { create(:user) }
    let_it_be(:group) { create(:group) }

    let(:opts) do
      {
        name: project_name,
        namespace_id: group.id
      }
    end

    before do
      group.add_maintainer(user)
      group.add_developer(other_user)
    end

    it 'updates authorization for current_user' do
      project = create_project(user, opts)

      expect(
        Ability.allowed?(user, :read_project, project)
      ).to be_truthy
    end

    it 'schedules authorization update for users with access to group', :sidekiq_inline do
      stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: false)

      expect(AuthorizedProjectsWorker).not_to(
        receive(:bulk_perform_async)
      )
      expect(AuthorizedProjectUpdate::ProjectRecalculateWorker).to(
        receive(:perform_async).and_call_original
      )
      expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to(
        receive(:bulk_perform_in).with(
          1.hour,
          array_including([user.id], [other_user.id]),
          batch_delay: 30.seconds, batch_size: 100
        ).and_call_original
      )

      project = create_project(user, opts)

      expect(
        Ability.allowed?(other_user, :developer_access, project)
      ).to be_truthy
    end
  end

  def create_project(user, opts)
    Projects::CreateService.new(user, opts).execute
  end

  context 'shared Runners config' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create :user }

    context 'when parent group is present' do
      let_it_be(:group, reload: true) do
        create(:group) do |group|
          group.add_owner(user)
        end
      end

      before do
        group.update!(shared_runners_enabled: shared_runners_enabled,
          allow_descendants_override_disabled_shared_runners: allow_to_override)

        user.refresh_authorized_projects # Ensure cache is warm
      end

      context 'default value based on parent group setting' do
        where(:shared_runners_enabled, :allow_to_override, :desired_config_for_new_project, :expected_result_for_project) do
          true  | false | nil | true
          false | true  | nil | false
          false | false | nil | false
        end

        with_them do
          it 'creates project following the parent config' do
            params = opts.merge(namespace_id: group.id)
            params = params.merge(shared_runners_enabled: desired_config_for_new_project) unless desired_config_for_new_project.nil?
            project = create_project(user, params)

            expect(project).to be_valid
            expect(project.shared_runners_enabled).to eq(expected_result_for_project)
            expect(project.project_namespace).to be_in_sync_with_project(project)
          end
        end
      end

      context 'parent group is present and allows desired config' do
        where(:shared_runners_enabled, :allow_to_override, :desired_config_for_new_project, :expected_result_for_project) do
          true  | false | true  | true
          true  | false | false | false
          false | true  | false | false
          false | true  | true  | true
          false | false | false | false
        end

        with_them do
          it 'creates project following the parent config' do
            params = opts.merge(namespace_id: group.id, shared_runners_enabled: desired_config_for_new_project)
            project = create_project(user, params)

            expect(project).to be_valid
            expect(project.shared_runners_enabled).to eq(expected_result_for_project)
            expect(project.project_namespace).to be_in_sync_with_project(project)
          end
        end
      end

      context 'parent group is present and disallows desired config' do
        where(:shared_runners_enabled, :allow_to_override, :desired_config_for_new_project) do
          false | false | true
        end

        with_them do
          it 'does not create project' do
            params = opts.merge(namespace_id: group.id, shared_runners_enabled: desired_config_for_new_project)
            project = create_project(user, params)

            expect(project.persisted?).to eq(false)
            expect(project).to be_invalid
            expect(project.errors[:shared_runners_enabled]).to include('cannot be enabled because parent group does not allow it')
            expect(project.project_namespace).to be_in_sync_with_project(project)
          end
        end
      end
    end

    context 'parent group is not present' do
      where(:desired_config, :expected_result) do
        true  | true
        false | false
        nil   | true
      end

      with_them do
        it 'follows desired config' do
          opts[:shared_runners_enabled] = desired_config unless desired_config.nil?
          project = create_project(user, opts)

          expect(project).to be_valid
          expect(project.shared_runners_enabled).to eq(expected_result)
          expect(project.project_namespace).to be_in_sync_with_project(project)
        end
      end
    end
  end

  context 'with group_runners_enabled' do
    subject(:project) { create_project(user, opts) }

    let(:opts) { super().merge(group_runners_enabled: true) }

    it 'creates ci_cd_settings relation' do
      expect(project.ci_cd_settings).to be_present
      expect(project.ci_cd_settings.group_runners_enabled).to be_truthy
    end
  end

  context 'when using access_level params' do
    def expect_not_disabled_features(project, exclude: [])
      ProjectFeature::FEATURES.excluding(exclude)
        .excluding(project.project_feature.send(:feature_validation_exclusion))
        .each do |feature|
          expect(project.project_feature.public_send(ProjectFeature.access_level_attribute(feature))).not_to eq(Featurable::DISABLED)
        end
    end

    # repository is tested on its own below because it requires other features to be set as well
    # package_registry has different behaviour and is modified from the model based on other attributes
    ProjectFeature::FEATURES.excluding(:repository, :package_registry).each do |feature|
      it "when using #{feature}", :aggregate_failures do
        feature_attribute = ProjectFeature.access_level_attribute(feature)
        opts[feature_attribute] = ProjectFeature.str_from_access_level(Featurable::DISABLED)
        project = create_project(user, opts)

        expect(project).to be_valid
        expect(project.project_feature.public_send(feature_attribute)).to eq(Featurable::DISABLED)

        expect_not_disabled_features(project, exclude: [feature])
      end
    end

    it 'when using repository', :aggregate_failures do
      # model validation will fail if builds or merge_requests have higher visibility than repository
      disabled = ProjectFeature.str_from_access_level(Featurable::DISABLED)
      opts[:repository_access_level] = disabled
      opts[:builds_access_level] = disabled
      opts[:merge_requests_access_level] = disabled
      project = create_project(user, opts)

      expect(project).to be_valid
      expect(project.project_feature.repository_access_level).to eq(Featurable::DISABLED)
      expect(project.project_feature.builds_access_level).to eq(Featurable::DISABLED)
      expect(project.project_feature.merge_requests_access_level).to eq(Featurable::DISABLED)

      expect_not_disabled_features(project, exclude: [:repository, :builds, :merge_requests])
    end
  end

  it 'adds pages unique domain', feature_category: :pages do
    stub_pages_setting(enabled: true)

    expect(Gitlab::Pages)
    .to receive(:add_unique_domain_to)
    .and_call_original

    project = create_project(user, opts)

    expect(project.project_setting.pages_unique_domain_enabled).to eq(true)
    expect(project.project_setting.pages_unique_domain).to be_present
  end
end
