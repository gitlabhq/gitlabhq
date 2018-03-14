require 'spec_helper'

describe Projects::CreateService, '#execute' do
  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:user) { create :user }
  let(:opts) do
    {
      name: 'GitLab',
      namespace_id: user.namespace.id
    }
  end

  it 'creates labels on Project creation if there are templates' do
    Label.create(title: "bug", template: true)
    project = create_project(user, opts)

    expect(project.labels).not_to be_empty
  end

  context 'user namespace' do
    it do
      project = create_project(user, opts)

      expect(project).to be_valid
      expect(project.owner).to eq(user)
      expect(project.team.masters).to include(user)
      expect(project.namespace).to eq(user.namespace)
    end
  end

  context "admin creates project with other user's namespace_id" do
    it 'sets the correct permissions' do
      admin = create(:admin)
      opts = {
        name: 'GitLab',
        namespace_id: user.namespace.id
      }
      project = create_project(admin, opts)

      expect(project).to be_persisted
      expect(project.owner).to eq(user)
      expect(project.team.masters).to contain_exactly(user)
      expect(project.namespace).to eq(user.namespace)
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

    it do
      project = create_project(user, opts.merge!(namespace_id: group.id))

      expect(project).to be_valid
      expect(project.owner).to eq(group)
      expect(project.namespace).to eq(group)
      expect(user.authorized_projects).to include(project)
    end
  end

  context 'error handling' do
    it 'handles invalid options' do
      opts[:default_branch] = 'master'
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
      Gitlab::Git::Repository.new(project.repository_storage, relative_path, 'foobar')
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

  context 'restricted visibility level' do
    before do
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])

      opts.merge!(
        visibility_level: Gitlab::VisibilityLevel::PUBLIC
      )
    end

    it 'does not allow a restricted visibility level for non-admins' do
      project = create_project(user, opts)
      expect(project).to respond_to(:errors)
      expect(project.errors.messages).to have_key(:visibility_level)
      expect(project.errors.messages[:visibility_level].first).to(
        match('restricted by your GitLab administrator')
      )
    end

    it 'allows a restricted visibility level for admins' do
      admin = create(:admin)
      project = create_project(admin, opts)

      expect(project.errors.any?).to be(false)
      expect(project.saved?).to be(true)
    end
  end

  context 'repository creation' do
    it 'synchronously creates the repository' do
      expect_any_instance_of(Project).to receive(:create_repository)

      project = create_project(user, opts)
      expect(project).to be_valid
      expect(project.owner).to eq(user)
      expect(project.namespace).to eq(user.namespace)
    end

    context 'when another repository already exists on disk' do
      let(:repository_storage) { 'default' }
      let(:repository_storage_path) { Gitlab.config.repositories.storages[repository_storage].legacy_disk_path }

      let(:opts) do
        {
          name: 'Existing',
          namespace_id: user.namespace.id
        }
      end

      context 'with legacy storage' do
        before do
          gitlab_shell.add_repository(repository_storage, "#{user.namespace.full_path}/existing")
        end

        after do
          gitlab_shell.remove_repository(repository_storage_path, "#{user.namespace.full_path}/existing")
        end

        it 'does not allow to create a project when path matches existing repository on disk' do
          project = create_project(user, opts)

          expect(project).not_to be_persisted
          expect(project).to respond_to(:errors)
          expect(project.errors.messages).to have_key(:base)
          expect(project.errors.messages[:base].first).to match('There is already a repository with that name on disk')
        end

        it 'does not allow to import project when path matches existing repository on disk' do
          project = create_project(user, opts.merge({ import_url: 'https://gitlab.com/gitlab-org/gitlab-test.git' }))

          expect(project).not_to be_persisted
          expect(project).to respond_to(:errors)
          expect(project.errors.messages).to have_key(:base)
          expect(project.errors.messages[:base].first).to match('There is already a repository with that name on disk')
        end
      end

      context 'with hashed storage' do
        let(:hash) { '6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b' }
        let(:hashed_path) { '@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b' }

        before do
          stub_application_setting(hashed_storage_enabled: true)
          allow(Digest::SHA2).to receive(:hexdigest) { hash }
        end

        before do
          gitlab_shell.add_repository(repository_storage, hashed_path)
        end

        after do
          gitlab_shell.remove_repository(repository_storage_path, hashed_path)
        end

        it 'does not allow to create a project when path matches existing repository on disk' do
          project = create_project(user, opts)

          expect(project).not_to be_persisted
          expect(project).to respond_to(:errors)
          expect(project.errors.messages).to have_key(:base)
          expect(project.errors.messages[:base].first).to match('There is already a repository with that name on disk')
        end
      end
    end
  end

  context 'when there is an active service template' do
    before do
      create(:service, project: nil, template: true, active: true)
    end

    it 'creates a service from this template' do
      project = create_project(user, opts)

      expect(project.services.count).to eq 1
    end
  end

  context 'when a bad service template is created' do
    it 'reports an error in the imported project' do
      opts[:import_url] = 'http://www.gitlab.com/gitlab-org/gitlab-ce'
      create(:service, type: 'DroneCiService', project: nil, template: true, active: true)

      project = create_project(user, opts)

      expect(project.errors.full_messages_for(:base).first).to match(/Unable to save project. Error: Unable to save DroneCiService/)
      expect(project.services.count).to eq 0
    end
  end

  context 'when skip_disk_validation is used' do
    it 'sets the project attribute' do
      opts[:skip_disk_validation] = true
      project = create_project(user, opts)

      expect(project.skip_disk_validation).to be_truthy
    end
  end

  it 'writes project full path to .git/config' do
    project = create_project(user, opts)

    expect(project.repository.rugged.config['gitlab.fullpath']).to eq project.full_path
  end

  def create_project(user, opts)
    Projects::CreateService.new(user, opts).execute
  end
end
