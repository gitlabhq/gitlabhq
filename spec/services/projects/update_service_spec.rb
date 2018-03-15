require 'spec_helper'

describe Projects::UpdateService do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:project) do
    create(:project, creator: user, namespace: user.namespace)
  end

  describe '#execute' do
    let(:gitlab_shell) { Gitlab::Shell.new }
    let(:admin) { create(:admin) }

    context 'when changing visibility level' do
      context 'when visibility_level is INTERNAL' do
        it 'updates the project to internal' do
          result = update_project(project, user, visibility_level: Gitlab::VisibilityLevel::INTERNAL)

          expect(result).to eq({ status: :success })
          expect(project).to be_internal
        end
      end

      context 'when visibility_level is PUBLIC' do
        it 'updates the project to public' do
          result = update_project(project, user, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          expect(result).to eq({ status: :success })
          expect(project).to be_public
        end
      end

      context 'when visibility levels are restricted to PUBLIC only' do
        before do
          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
        end

        context 'when visibility_level is INTERNAL' do
          it 'updates the project to internal' do
            result = update_project(project, user, visibility_level: Gitlab::VisibilityLevel::INTERNAL)
            expect(result).to eq({ status: :success })
            expect(project).to be_internal
          end
        end

        context 'when visibility_level is PUBLIC' do
          it 'does not update the project to public' do
            result = update_project(project, user, visibility_level: Gitlab::VisibilityLevel::PUBLIC)

            expect(result).to eq({ status: :error, message: 'New visibility level not allowed!' })
            expect(project).to be_private
          end

          context 'when updated by an admin' do
            it 'updates the project to public' do
              result = update_project(project, admin, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
              expect(result).to eq({ status: :success })
              expect(project).to be_public
            end
          end
        end
      end

      context 'when project visibility is higher than parent group' do
        let(:group) { create(:group, visibility_level: Gitlab::VisibilityLevel::INTERNAL) }

        before do
          project.update(namespace: group, visibility_level: group.visibility_level)
        end

        it 'does not update project visibility level' do
          result = update_project(project, admin, visibility_level: Gitlab::VisibilityLevel::PUBLIC)

          expect(result).to eq({ status: :error, message: 'Visibility level public is not allowed in a internal group.' })
          expect(project.reload).to be_internal
        end
      end
    end

    describe 'when updating project that has forks' do
      let(:project) { create(:project, :internal) }
      let(:forked_project) { fork_project(project) }

      it 'updates forks visibility level when parent set to more restrictive' do
        opts = { visibility_level: Gitlab::VisibilityLevel::PRIVATE }

        expect(project).to be_internal
        expect(forked_project).to be_internal

        expect(update_project(project, admin, opts)).to eq({ status: :success })

        expect(project).to be_private
        expect(forked_project.reload).to be_private
      end

      it 'does not update forks visibility level when parent set to less restrictive' do
        opts = { visibility_level: Gitlab::VisibilityLevel::PUBLIC }

        expect(project).to be_internal
        expect(forked_project).to be_internal

        expect(update_project(project, admin, opts)).to eq({ status: :success })

        expect(project).to be_public
        expect(forked_project.reload).to be_internal
      end
    end

    context 'when updating a default branch' do
      let(:project) { create(:project, :repository) }

      it 'changes a default branch' do
        update_project(project, admin, default_branch: 'feature')

        expect(Project.find(project.id).default_branch).to eq 'feature'
      end

      it 'does not change a default branch' do
        # The branch 'unexisted-branch' does not exist.
        update_project(project, admin, default_branch: 'unexisted-branch')

        expect(Project.find(project.id).default_branch).to eq 'master'
      end
    end

    context 'when we update project but not enabling a wiki' do
      it 'does not try to create an empty wiki' do
        FileUtils.rm_rf(project.wiki.repository.path)

        result = update_project(project, user, { name: 'test1' })

        expect(result).to eq({ status: :success })
        expect(project.wiki_repository_exists?).to be false
      end

      it 'handles empty project feature attributes' do
        project.project_feature.update(wiki_access_level: ProjectFeature::DISABLED)

        result = update_project(project, user, { name: 'test1' })

        expect(result).to eq({ status: :success })
        expect(project.wiki_repository_exists?).to be false
      end
    end

    context 'when enabling a wiki' do
      it 'creates a wiki' do
        project.project_feature.update(wiki_access_level: ProjectFeature::DISABLED)
        FileUtils.rm_rf(project.wiki.repository.path)

        result = update_project(project, user, project_feature_attributes: { wiki_access_level: ProjectFeature::ENABLED })

        expect(result).to eq({ status: :success })
        expect(project.wiki_repository_exists?).to be true
        expect(project.wiki_enabled?).to be true
      end

      it 'logs an error and creates a metric when wiki can not be created' do
        project.project_feature.update(wiki_access_level: ProjectFeature::DISABLED)

        expect_any_instance_of(ProjectWiki).to receive(:wiki).and_raise(ProjectWiki::CouldNotCreateWikiError)
        expect_any_instance_of(described_class).to receive(:log_error).with("Could not create wiki for #{project.full_name}")
        expect(Gitlab::Metrics).to receive(:counter)

        update_project(project, user, project_feature_attributes: { wiki_access_level: ProjectFeature::ENABLED })
      end
    end

    context 'when updating a project that contains container images' do
      before do
        stub_container_registry_config(enabled: true)
        stub_container_registry_tags(repository: /image/, tags: %w[rc1])
        create(:container_repository, project: project, name: :image)
      end

      it 'does not allow to rename the project' do
        result = update_project(project, admin, path: 'renamed')

        expect(result).to include(status: :error)
        expect(result[:message]).to match(/contains container registry tags/)
      end

      it 'allows to update other settings' do
        result = update_project(project, admin, public_builds: true)

        expect(result[:status]).to eq :success
        expect(project.reload.public_builds).to be true
      end
    end

    context 'when renaming a project' do
      let(:repository_storage) { 'default' }
      let(:repository_storage_path) { Gitlab.config.repositories.storages[repository_storage].legacy_disk_path }

      context 'with legacy storage' do
        let(:project) { create(:project, :legacy_storage, :repository, creator: user, namespace: user.namespace) }

        before do
          gitlab_shell.create_repository(repository_storage, "#{user.namespace.full_path}/existing")
        end

        after do
          gitlab_shell.remove_repository(repository_storage_path, "#{user.namespace.full_path}/existing")
        end

        it 'does not allow renaming when new path matches existing repository on disk' do
          result = update_project(project, admin, path: 'existing')

          expect(result).to include(status: :error)
          expect(result[:message]).to match('There is already a repository with that name on disk')
          expect(project).not_to be_valid
          expect(project.errors.messages).to have_key(:base)
          expect(project.errors.messages[:base]).to include('There is already a repository with that name on disk')
        end
      end

      context 'with hashed storage' do
        let(:project) { create(:project, :repository, creator: user, namespace: user.namespace) }

        before do
          stub_application_setting(hashed_storage_enabled: true)
        end

        it 'does not check if new path matches existing repository on disk' do
          expect(project).not_to receive(:repository_with_same_path_already_exists?)

          result = update_project(project, admin, path: 'existing')

          expect(result).to include(status: :success)
        end
      end
    end

    context 'when passing invalid parameters' do
      it 'returns an error result when record cannot be updated' do
        result = update_project(project, admin, { name: 'foo&bar' })

        expect(result).to eq({
          status: :error,
          message: "Name can contain only letters, digits, emojis, '_', '.', dash, space. It must start with letter, digit, emoji or '_'."
        })
      end
    end

    context 'when updating #pages_https_only', :https_pages_enabled do
      subject(:call_service) do
        update_project(project, admin, pages_https_only: false)
      end

      it 'updates the attribute' do
        expect { call_service }
          .to change { project.pages_https_only? }
          .to(false)
      end

      it 'calls Projects::UpdatePagesConfigurationService' do
        expect(Projects::UpdatePagesConfigurationService)
          .to receive(:new)
          .with(project)
          .and_call_original

        call_service
      end
    end
  end

  describe '#run_auto_devops_pipeline?' do
    subject { described_class.new(project, user).run_auto_devops_pipeline? }

    context 'when master contains a .gitlab-ci.yml file' do
      before do
        allow(project.repository).to receive(:gitlab_ci_yml).and_return("script: ['test']")
      end

      it { is_expected.to eq(false) }
    end

    context 'when auto devops is explicitly enabled' do
      before do
        project.create_auto_devops!(enabled: true)
      end

      it { is_expected.to eq(true) }
    end

    context 'when auto devops is explicitly disabled' do
      before do
        project.create_auto_devops!(enabled: false)
      end

      it { is_expected.to eq(false) }
    end

    context 'when auto devops is set to instance setting' do
      before do
        project.create_auto_devops!(enabled: nil)
        allow(project.auto_devops).to receive(:previous_changes).and_return('enabled' => true)
      end

      context 'when auto devops is enabled system-wide' do
        before do
          stub_application_setting(auto_devops_enabled: true)
        end

        it { is_expected.to eq(true) }
      end

      context 'when auto devops is disabled system-wide' do
        before do
          stub_application_setting(auto_devops_enabled: false)
        end

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#auto_devops_conflicts_custom_yml?' do
    subject { described_class.new(project, user).auto_devops_conflicts_custom_yml? }

    before do
      project.create_auto_devops!(enabled: nil)
    end

    context 'when auto_devops was enabled' do
      before do
        allow(project.auto_devops).to receive(:previous_changes).and_return('enabled' => true)
      end

      it { is_expected.to eq(false) }
    end

    context 'when auto_devops is not enabled' do
      before do
        allow(project.auto_devops).to receive(:enabled?).and_return(false)
      end

      it { is_expected.to eq(false) }
    end

    context 'when auto_devops is enabled' do
      before do
        allow(project.auto_devops).to receive(:enabled?).and_return(true)
      end

      context 'when custom CI path is set' do
        before do
          allow(project).to receive_message_chain(:ci_config_path, :present?).and_return(true)
        end

        it { is_expected.to eq(true) }
      end
    end
  end

  def update_project(project, user, opts)
    described_class.new(project, user, opts).execute
  end
end
