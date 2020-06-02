# frozen_string_literal: true

require 'spec_helper'

describe Projects::CreateService, '#execute' do
  include ExternalAuthorizationServiceHelpers
  include GitHelpers

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

    created_label = project.reload.labels.last

    expect(created_label.type).to eq('ProjectLabel')
    expect(created_label.project_id).to eq(project.id)
    expect(created_label.title).to eq('bug')
  end

  context 'user namespace' do
    it do
      project = create_project(user, opts)

      expect(project).to be_valid
      expect(project.owner).to eq(user)
      expect(project.team.maintainers).to include(user)
      expect(project.namespace).to eq(user.namespace)
    end
  end

  describe 'after create actions' do
    it 'invalidate personal_projects_count caches' do
      expect(user).to receive(:invalidate_personal_projects_count)

      create_project(user, opts)
    end

    it 'creates associated project settings' do
      project = create_project(user, opts)

      expect(project.project_setting).to be_persisted
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
      expect(project.team.maintainers).to contain_exactly(user)
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
      expect(project.team.owners).to include(user)
      expect(user.authorized_projects).to include(project)
    end
  end

  context 'error handling' do
    it 'handles invalid options' do
      opts[:default_branch] = 'master'
      expect(create_project(user, opts)).to eq(nil)
    end

    it 'sets invalid service as inactive' do
      create(:service, type: 'JiraService', project: nil, template: true, active: true)

      project = create_project(user, opts)
      service = project.services.first

      expect(project).to be_persisted
      expect(service.active).to be false
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
    it 'stores import data and URL' do
      import_data = { data: { 'test' => 'some data' } }
      project = create_project(user, { name: 'test', import_url: 'http://import-url', import_data: import_data })

      expect(project.import_data).to be_persisted
      expect(project.import_data.data).to eq(import_data[:data])
      expect(project.import_url).to eq('http://import-url')
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

    before do
      stub_application_setting(default_project_visibility: Gitlab::VisibilityLevel::INTERNAL)
      group.add_developer(user)

      opts.merge!(
        visibility: 'private',
        name: 'test',
        namespace: group,
        path: 'foo'
      )
    end

    it 'creates a private project' do
      project = create_project(user, opts)

      expect(project).to respond_to(:errors)

      expect(project.errors.any?).to be(false)
      expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
      expect(project.saved?).to be(true)
      expect(project.valid?).to be(true)
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
      end

      it 'allows a restricted visibility level for admins' do
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
        expect(instance).to receive(:create_repository)
      end

      project = create_project(user, opts)
      expect(project).to be_valid
      expect(project.owner).to eq(user)
      expect(project.namespace).to eq(user.namespace)
    end

    context 'when another repository already exists on disk' do
      let(:opts) do
        {
          name: 'Existing',
          namespace_id: user.namespace.id
        }
      end

      context 'with legacy storage' do
        let(:fake_repo_path) { File.join(TestEnv.repos_path, user.namespace.full_path, 'existing.git') }

        before do
          stub_application_setting(hashed_storage_enabled: false)
          TestEnv.create_bare_repository(fake_repo_path)
        end

        after do
          FileUtils.rm_rf(fake_repo_path)
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
        let(:fake_repo_path) { File.join(TestEnv.repos_path, "#{hashed_path}.git") }

        before do
          allow(Digest::SHA2).to receive(:hexdigest) { hash }
          TestEnv.create_bare_repository(fake_repo_path)
        end

        after do
          FileUtils.rm_rf(fake_repo_path)
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

  context 'when readme initialization is requested' do
    it 'creates README.md' do
      opts[:initialize_with_readme] = '1'

      project = create_project(user, opts)

      expect(project.repository.commit_count).to be(1)
      expect(project.repository.readme.name).to eql('README.md')
      expect(project.repository.readme.data).to include('# GitLab')
    end
  end

  describe 'create service for the project' do
    subject(:project) { create_project(user, opts) }

    context 'when there is an active instance-level and an active template integration' do
      before do
        create(:prometheus_service, :instance, api_url: 'https://prometheus.instance.com/')
        create(:prometheus_service, :template, api_url: 'https://prometheus.template.com/')
      end

      it 'creates a service from the instance-level integration' do
        expect(project.services.count).to eq(1)
        expect(project.services.first.api_url).to eq('https://prometheus.instance.com/')
      end
    end

    context 'when there is an active service template' do
      before do
        create(:prometheus_service, :template, active: true)
      end

      it 'creates a service from the template' do
        expect(project.services.count).to eq(1)
      end
    end

    context 'when there is an invalid integration' do
      before do
        create(:service, :template, type: 'DroneCiService', active: true)
      end

      it 'creates an inactive service' do
        expect(project).to be_persisted
        expect(project.services.first.active).to be false
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

  it 'writes project full path to .git/config' do
    project = create_project(user, opts)
    rugged = rugged_repo(project.repository)

    expect(rugged.config['gitlab.fullpath']).to eq project.full_path
  end

  context 'when project has access to shared service' do
    context 'Prometheus application is shared via group cluster' do
      let(:cluster) { create(:cluster, :group, groups: [group]) }
      let(:group) do
        create(:group).tap do |group|
          group.add_owner(user)
        end
      end

      before do
        create(:clusters_applications_prometheus, :installed, cluster: cluster)
      end

      it 'creates PrometheusService record', :aggregate_failures do
        project = create_project(user, opts.merge!(namespace_id: group.id))
        service = project.prometheus_service

        expect(service.active).to be true
        expect(service.manual_configuration?).to be false
        expect(service.persisted?).to be true
      end
    end

    context 'Prometheus application is shared via instance cluster' do
      let(:cluster) { create(:cluster, :instance) }

      before do
        create(:clusters_applications_prometheus, :installed, cluster: cluster)
      end

      it 'creates PrometheusService record', :aggregate_failures do
        project = create_project(user, opts)
        service = project.prometheus_service

        expect(service.active).to be true
        expect(service.manual_configuration?).to be false
        expect(service.persisted?).to be true
      end

      it 'cleans invalid record and logs warning', :aggregate_failures do
        invalid_service_record = build(:prometheus_service, properties: { api_url: nil, manual_configuration: true }.to_json)
        allow_next_instance_of(Project) do |instance|
          allow(instance).to receive(:build_prometheus_service).and_return(invalid_service_record)
        end

        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(an_instance_of(ActiveRecord::RecordInvalid), include(extra: { project_id: a_kind_of(Integer) }))
        project = create_project(user, opts)

        expect(project.prometheus_service).to be_nil
      end
    end

    context 'shared Prometheus application is not available' do
      it 'does not persist PrometheusService record', :aggregate_failures do
        project = create_project(user, opts)

        expect(project.prometheus_service).to be_nil
      end
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
        .to receive(:access_allowed?).with(user, 'new-label', any_args) { true }

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

  it_behaves_like 'measurable service' do
    before do
      opts.merge!(
        current_user: user,
        path: 'foo'
      )
    end

    let(:base_log_data) do
      {
        class: Projects::CreateService.name,
        current_user: user.name,
        project_full_path: "#{user.namespace.full_path}/#{opts[:path]}"
      }
    end

    after do
      create_project(user, opts)
    end
  end

  context 'with specialized_project_authorization_workers' do
    let_it_be(:other_user) { create(:user) }
    let_it_be(:group) { create(:group) }

    let(:opts) do
      {
        name: 'GitLab',
        namespace_id: group.id
      }
    end

    before do
      group.add_maintainer(user)
      group.add_developer(other_user)
    end

    it 'updates authorization for current_user' do
      expect(Users::RefreshAuthorizedProjectsService).to(
        receive(:new).with(user).and_call_original
      )

      project = create_project(user, opts)

      expect(
        Ability.allowed?(user, :read_project, project)
      ).to be_truthy
    end

    it 'schedules authorization update for users with access to group' do
      expect(AuthorizedProjectsWorker).not_to(
        receive(:bulk_perform_async)
      )
      expect(AuthorizedProjectUpdate::ProjectCreateWorker).to(
        receive(:perform_async).and_call_original
      )
      expect(AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker).to(
        receive(:bulk_perform_in)
          .with(1.hour,
                array_including([user.id], [other_user.id]),
                batch_delay: 30.seconds, batch_size: 100)
          .and_call_original
      )

      create_project(user, opts)
    end

    context 'when feature is disabled' do
      before do
        stub_feature_flags(specialized_project_authorization_workers: false)
      end

      it 'updates authorization for current_user' do
        expect(Users::RefreshAuthorizedProjectsService).to(
          receive(:new).with(user).and_call_original
        )

        project = create_project(user, opts)

        expect(
          Ability.allowed?(user, :read_project, project)
        ).to be_truthy
      end

      it 'uses AuthorizedProjectsWorker' do
        expect(AuthorizedProjectsWorker).to(
          receive(:bulk_perform_async).with(array_including([user.id], [other_user.id])).and_call_original
        )
        expect(AuthorizedProjectUpdate::ProjectCreateWorker).not_to(
          receive(:perform_async)
        )
        expect(AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker).not_to(
          receive(:bulk_perform_in)
        )

        create_project(user, opts)
      end
    end
  end

  def create_project(user, opts)
    Projects::CreateService.new(user, opts).execute
  end
end
