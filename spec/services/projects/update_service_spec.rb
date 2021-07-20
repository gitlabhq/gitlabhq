# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UpdateService do
  include ExternalAuthorizationServiceHelpers
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:project) do
    create(:project, creator: user, namespace: user.namespace)
  end

  describe '#execute' do
    let(:admin) { create(:admin) }

    context 'when changing visibility level' do
      context 'when visibility_level changes to INTERNAL' do
        it 'updates the project to internal' do
          expect(TodosDestroyer::ProjectPrivateWorker).not_to receive(:perform_in)

          result = update_project(project, user, visibility_level: Gitlab::VisibilityLevel::INTERNAL)

          expect(result).to eq({ status: :success })
          expect(project).to be_internal
        end
      end

      context 'when visibility_level changes to PUBLIC' do
        it 'updates the project to public' do
          expect(TodosDestroyer::ProjectPrivateWorker).not_to receive(:perform_in)

          result = update_project(project, user, visibility_level: Gitlab::VisibilityLevel::PUBLIC)

          expect(result).to eq({ status: :success })
          expect(project).to be_public
        end

        context 'and project is PRIVATE' do
          it 'does not unlink project from fork network' do
            expect(Projects::UnlinkForkService).not_to receive(:new)

            update_project(project, user, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          end
        end
      end

      context 'when visibility_level changes to PRIVATE' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        it 'updates the project to private' do
          expect(TodosDestroyer::ProjectPrivateWorker).to receive(:perform_in).with(Todo::WAIT_FOR_DELETE, project.id)
          expect(TodosDestroyer::ConfidentialIssueWorker).to receive(:perform_in).with(Todo::WAIT_FOR_DELETE, nil, project.id)

          result = update_project(project, user, visibility_level: Gitlab::VisibilityLevel::PRIVATE)

          expect(result).to eq({ status: :success })
          expect(project).to be_private
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
            context 'when admin mode is enabled', :enable_admin_mode do
              it 'updates the project to public' do
                result = update_project(project, admin, visibility_level: Gitlab::VisibilityLevel::PUBLIC)

                expect(result).to eq({ status: :success })
                expect(project).to be_public
              end
            end

            context 'when admin mode is disabled' do
              it 'does not update the project to public' do
                result = update_project(project, admin, visibility_level: Gitlab::VisibilityLevel::PUBLIC)

                expect(result).to eq({ status: :error, message: 'New visibility level not allowed!' })
                expect(project).to be_private
              end
            end
          end
        end
      end

      context 'when project visibility is higher than parent group' do
        let(:group) { create(:group, visibility_level: Gitlab::VisibilityLevel::INTERNAL) }

        before do
          project.update!(namespace: group, visibility_level: group.visibility_level)
        end

        it 'does not update project visibility level even if admin', :enable_admin_mode do
          result = update_project(project, admin, visibility_level: Gitlab::VisibilityLevel::PUBLIC)

          expect(result).to eq({ status: :error, message: 'Visibility level public is not allowed in a internal group.' })
          expect(project.reload).to be_internal
        end
      end

      context 'when updating shared runners' do
        context 'can enable shared runners' do
          let(:group) { create(:group, shared_runners_enabled: true) }
          let(:project) { create(:project, namespace: group, shared_runners_enabled: false) }

          it 'enables shared runners' do
            result = update_project(project, user, shared_runners_enabled: true)

            expect(result).to eq({ status: :success })
            expect(project.reload.shared_runners_enabled).to be_truthy
          end
        end

        context 'cannot enable shared runners' do
          let(:group) { create(:group, :shared_runners_disabled) }
          let(:project) { create(:project, namespace: group, shared_runners_enabled: false) }

          it 'does not enable shared runners' do
            result = update_project(project, user, shared_runners_enabled: true)

            expect(result).to eq({ status: :error, message: 'Shared runners enabled cannot be enabled because parent group does not allow it' })
            expect(project.reload.shared_runners_enabled).to be_falsey
          end
        end
      end
    end

    describe 'when updating project that has forks' do
      let(:project) { create(:project, :internal) }
      let(:user) { project.owner }
      let(:forked_project) { fork_project(project) }

      context 'and unlink forks feature flag is off' do
        before do
          stub_feature_flags(unlink_fork_network_upon_visibility_decrease: false)
        end

        it 'updates forks visibility level when parent set to more restrictive' do
          opts = { visibility_level: Gitlab::VisibilityLevel::PRIVATE }

          expect(project).to be_internal
          expect(forked_project).to be_internal

          expect(update_project(project, user, opts)).to eq({ status: :success })

          expect(project).to be_private
          expect(forked_project.reload).to be_private
        end

        it 'does not update forks visibility level when parent set to less restrictive' do
          opts = { visibility_level: Gitlab::VisibilityLevel::PUBLIC }

          expect(project).to be_internal
          expect(forked_project).to be_internal

          expect(update_project(project, user, opts)).to eq({ status: :success })

          expect(project).to be_public
          expect(forked_project.reload).to be_internal
        end
      end

      context 'and unlink forks feature flag is on' do
        it 'does not change visibility of forks' do
          opts = { visibility_level: Gitlab::VisibilityLevel::PRIVATE }

          expect(project).to be_internal
          expect(forked_project).to be_internal

          expect(update_project(project, user, opts)).to eq({ status: :success })

          expect(project).to be_private
          expect(forked_project.reload).to be_internal
        end
      end
    end

    context 'when updating a default branch' do
      let(:project) { create(:project, :repository) }

      it 'changes default branch, tracking the previous branch' do
        previous_default_branch = project.default_branch

        update_project(project, admin, default_branch: 'feature')

        project.reload

        expect(project.default_branch).to eq('feature')
        expect(project.previous_default_branch).to eq(previous_default_branch)

        update_project(project, admin, default_branch: previous_default_branch)

        project.reload

        expect(project.default_branch).to eq(previous_default_branch)
        expect(project.previous_default_branch).to eq('feature')
      end

      it 'does not change a default branch' do
        # The branch 'unexisted-branch' does not exist.
        update_project(project, admin, default_branch: 'unexisted-branch')

        project.reload

        expect(project.default_branch).to eq 'master'
        expect(project.previous_default_branch).to be_nil
      end
    end

    context 'when we update project but not enabling a wiki' do
      it 'does not try to create an empty wiki' do
        TestEnv.rm_storage_dir(project.repository_storage, project.wiki.path)

        result = update_project(project, user, { name: 'test1' })

        expect(result).to eq({ status: :success })
        expect(project.wiki_repository_exists?).to be false
      end

      it 'handles empty project feature attributes' do
        project.project_feature.update!(wiki_access_level: ProjectFeature::DISABLED)

        result = update_project(project, user, { name: 'test1' })

        expect(result).to eq({ status: :success })
        expect(project.wiki_repository_exists?).to be false
      end
    end

    context 'when enabling a wiki' do
      it 'creates a wiki' do
        project.project_feature.update!(wiki_access_level: ProjectFeature::DISABLED)
        TestEnv.rm_storage_dir(project.repository_storage, project.wiki.path)

        result = update_project(project, user, project_feature_attributes: { wiki_access_level: ProjectFeature::ENABLED })

        expect(result).to eq({ status: :success })
        expect(project.wiki_repository_exists?).to be true
        expect(project.wiki_enabled?).to be true
      end

      it 'logs an error and creates a metric when wiki can not be created' do
        project.project_feature.update!(wiki_access_level: ProjectFeature::DISABLED)

        expect_any_instance_of(ProjectWiki).to receive(:wiki).and_raise(Wiki::CouldNotCreateWikiError)
        expect_any_instance_of(described_class).to receive(:log_error).with("Could not create wiki for #{project.full_name}")

        counter = double(:counter)
        expect(Gitlab::Metrics).to receive(:counter).with(:wiki_can_not_be_created_total, 'Counts the times we failed to create a wiki').and_return(counter)
        expect(counter).to receive(:increment)

        update_project(project, user, project_feature_attributes: { wiki_access_level: ProjectFeature::ENABLED })
      end
    end

    context 'when changing feature visibility to private' do
      it 'updates the visibility correctly' do
        expect(TodosDestroyer::PrivateFeaturesWorker)
          .to receive(:perform_in).with(Todo::WAIT_FOR_DELETE, project.id)

        result = update_project(project, user, project_feature_attributes:
                                 { issues_access_level: ProjectFeature::PRIVATE }
        )

        expect(result).to eq({ status: :success })
        expect(project.project_feature.issues_access_level).to be(ProjectFeature::PRIVATE)
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
      let(:fake_repo_path) { File.join(TestEnv.repos_path, user.namespace.full_path, 'existing.git') }

      context 'with legacy storage' do
        let(:project) { create(:project, :legacy_storage, :repository, creator: user, namespace: user.namespace) }

        before do
          TestEnv.create_bare_repository(fake_repo_path)
        end

        after do
          FileUtils.rm_rf(fake_repo_path)
        end

        it 'does not allow renaming when new path matches existing repository on disk' do
          result = update_project(project, admin, path: 'existing')

          expect(result).to include(status: :error)
          expect(result[:message]).to match('There is already a repository with that name on disk')
          expect(project).not_to be_valid
          expect(project.errors.messages).to have_key(:base)
          expect(project.errors.messages[:base]).to include('There is already a repository with that name on disk')
        end

        context 'when hashed storage is enabled' do
          before do
            stub_application_setting(hashed_storage_enabled: true)
          end

          it 'migrates project to a hashed storage instead of renaming the repo to another legacy name' do
            result = update_project(project, admin, path: 'new-path')

            expect(result).not_to include(status: :error)
            expect(project).to be_valid
            expect(project.errors).to be_empty
            expect(project.reload.hashed_storage?(:repository)).to be_truthy
          end
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

    shared_examples 'updating pages configuration' do
      it 'schedules the `PagesUpdateConfigurationWorker` when pages are deployed' do
        project.mark_pages_as_deployed

        expect(PagesUpdateConfigurationWorker).to receive(:perform_async).with(project.id)

        subject
      end

      it "does not schedule a job when pages aren't deployed" do
        project.mark_pages_as_not_deployed

        expect(PagesUpdateConfigurationWorker).not_to receive(:perform_async).with(project.id)

        subject
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

      it_behaves_like 'updating pages configuration'
    end

    context 'when updating #pages_access_level' do
      subject(:call_service) do
        update_project(project, admin, project_feature_attributes: { pages_access_level: ProjectFeature::ENABLED })
      end

      it 'updates the attribute' do
        expect { call_service }
          .to change { project.project_feature.pages_access_level }
          .to(ProjectFeature::ENABLED)
      end

      it_behaves_like 'updating pages configuration'
    end

    context 'when updating #emails_disabled' do
      it 'updates the attribute for the project owner' do
        expect { update_project(project, user, emails_disabled: true) }
          .to change { project.emails_disabled }
          .to(true)
      end

      it 'does not update when not project owner' do
        maintainer = create(:user)
        project.add_user(maintainer, :maintainer)

        expect { update_project(project, maintainer, emails_disabled: true) }
          .not_to change { project.emails_disabled }
      end
    end

    context 'with external authorization enabled' do
      before do
        enable_external_authorization_service_check

        allow(::Gitlab::ExternalAuthorization)
          .to receive(:access_allowed?).with(user, 'default_label', project.full_path).and_call_original
      end

      it 'does not save the project with an error if the service denies access' do
        expect(::Gitlab::ExternalAuthorization)
          .to receive(:access_allowed?).with(user, 'new-label') { false }

        result = update_project(project, user, { external_authorization_classification_label: 'new-label' })

        expect(result[:message]).to be_present
        expect(result[:status]).to eq(:error)
      end

      it 'saves the new label if the service allows access' do
        expect(::Gitlab::ExternalAuthorization)
          .to receive(:access_allowed?).with(user, 'new-label') { true }

        result = update_project(project, user, { external_authorization_classification_label: 'new-label' })

        expect(result[:status]).to eq(:success)
        expect(project.reload.external_authorization_classification_label).to eq('new-label')
      end

      it 'checks the default label when the classification label was cleared' do
        expect(::Gitlab::ExternalAuthorization)
          .to receive(:access_allowed?).with(user, 'default_label') { true }

        update_project(project, user, { external_authorization_classification_label: '' })
      end

      it 'does not check the label when it does not change' do
        expect(::Gitlab::ExternalAuthorization).to receive(:access_allowed?).once

        update_project(project, user, { name: 'New name' })
      end
    end

    context 'when updating nested attributes for prometheus integration' do
      context 'prometheus integration exists' do
        let(:prometheus_integration_attributes) do
          attributes_for(:prometheus_integration,
                         project: project,
                         properties: { api_url: "http://new.prometheus.com", manual_configuration: "0" }
                        )
        end

        let!(:prometheus_integration) do
          create(:prometheus_integration,
                 project: project,
                 properties: { api_url: "http://old.prometheus.com", manual_configuration: "0" }
                )
        end

        it 'updates existing record' do
          expect { update_project(project, user, prometheus_integration_attributes: prometheus_integration_attributes) }
            .to change { prometheus_integration.reload.api_url }
            .from("http://old.prometheus.com")
            .to("http://new.prometheus.com")
        end
      end

      context 'prometheus integration does not exist' do
        context 'valid parameters' do
          let(:prometheus_integration_attributes) do
            attributes_for(:prometheus_integration,
                           project: project,
                           properties: { api_url: "http://example.prometheus.com", manual_configuration: "0" }
                          )
          end

          it 'creates new record' do
            expect { update_project(project, user, prometheus_integration_attributes: prometheus_integration_attributes) }
              .to change { ::Integrations::Prometheus.where(project: project).count }
              .from(0)
              .to(1)
          end
        end

        context 'invalid parameters' do
          let(:prometheus_integration_attributes) do
            attributes_for(:prometheus_integration,
                           project: project,
                           properties: { api_url: nil, manual_configuration: "1" }
                          )
          end

          it 'does not create new record' do
            expect { update_project(project, user, prometheus_integration_attributes: prometheus_integration_attributes) }
              .not_to change { ::Integrations::Prometheus.where(project: project).count }
          end
        end
      end
    end

    describe 'when changing repository_storage' do
      let(:repository_read_only) { false }
      let(:project) { create(:project, :repository, repository_read_only: repository_read_only) }
      let(:opts) { { repository_storage: 'test_second_storage' } }

      before do
        stub_storage_settings('test_second_storage' => { 'path' => 'tmp/tests/extra_storage' })
      end

      shared_examples 'the transfer was not scheduled' do
        it 'does not schedule the transfer' do
          expect do
            update_project(project, user, opts)
          end.not_to change(project.repository_storage_moves, :count)
        end
      end

      context 'authenticated as admin' do
        let(:user) { create(:admin) }

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'schedules the transfer of the repository to the new storage and locks the project' do
            update_project(project, admin, opts)

            expect(project).to be_repository_read_only
            expect(project.repository_storage_moves.last).to have_attributes(
              state: ::Projects::RepositoryStorageMove.state_machines[:state].states[:scheduled].value,
              source_storage_name: 'default',
              destination_storage_name: 'test_second_storage'
            )
          end
        end

        context 'when admin mode is disabled' do
          it_behaves_like 'the transfer was not scheduled'
        end

        context 'the repository is read-only' do
          let(:repository_read_only) { true }

          it_behaves_like 'the transfer was not scheduled'
        end

        context 'the storage has not changed' do
          let(:opts) { { repository_storage: 'default' } }

          it_behaves_like 'the transfer was not scheduled'
        end

        context 'the storage does not exist' do
          let(:opts) { { repository_storage: 'nonexistent' } }

          it_behaves_like 'the transfer was not scheduled'
        end
      end

      context 'authenticated as user' do
        let(:user) { create(:user) }

        it_behaves_like 'the transfer was not scheduled'
      end
    end

    describe 'when updating topics' do
      let(:project) { create(:project, topic_list: 'topic1, topic2') }

      it 'update using topics' do
        result = update_project(project, user, { topics: 'topics' })

        expect(result[:status]).to eq(:success)
        expect(project.topic_list).to eq(%w[topics])
      end

      it 'update using topic_list' do
        result = update_project(project, user, { topic_list: 'topic_list' })

        expect(result[:status]).to eq(:success)
        expect(project.topic_list).to eq(%w[topic_list])
      end

      it 'update using tag_list (deprecated)' do
        result = update_project(project, user, { tag_list: 'tag_list' })

        expect(result[:status]).to eq(:success)
        expect(project.topic_list).to eq(%w[tag_list])
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

    context 'when auto devops is nil' do
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
        project.reload

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

  def update_project(project, user, opts)
    described_class.new(project, user, opts).execute
  end
end
