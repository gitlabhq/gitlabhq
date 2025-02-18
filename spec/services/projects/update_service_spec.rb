# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Projects::UpdateService, feature_category: :groups_and_projects do
  include ExternalAuthorizationServiceHelpers
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:project) do
    create(:project, creator: user, namespace: user.namespace)
  end

  shared_examples 'publishing Projects::ProjectAttributesChangedEvent' do |params:, attributes:|
    it "publishes Projects::ProjectAttributesChangedEvent" do
      expect { update_project(project, user, params) }
        .to publish_event(Projects::ProjectAttributesChangedEvent)
        .with(
          project_id: project.id,
          namespace_id: project.namespace_id,
          root_namespace_id: project.root_namespace.id,
          attributes: attributes
        )
    end
  end

  describe '#execute' do
    let(:admin) { create(:admin) }

    let_it_be(:maintainer) { create(:user) }
    let_it_be(:developer) { create(:user) }
    let_it_be(:owner) { create(:user) }

    context 'when changing restrict_user_defined_variables' do
      using RSpec::Parameterized::TableSyntax

      where(:current_user_role, :project_minimum_role, :from_value, :to_value, :status) do
        :owner      | :developer  | true  | false | :success
        :owner      | :maintainer | true  | false | :success
        :owner      | :developer  | false | true  | :success
        :owner      | :maintainer | false | true  | :success
        :maintainer | :developer  | true  | false | :success
        :maintainer | :maintainer | true  | false | :success
        :maintainer | :owner      | true  | false | :api_error
        :maintainer | :owner      | false | true  | :api_error
        :maintainer | :owner      | true  | true  | :success
        :developer  | :owner      | true  | false | :api_error
        :developer  | :developer  | true  | false | :api_error
        :developer  | :maintainer | true  | false | :api_error
      end

      with_them do
        let(:current_user) { public_send(current_user_role) }

        before do
          project.add_maintainer(maintainer)
          project.add_developer(developer)
          project.add_owner(owner)

          ci_cd_settings = project.ci_cd_settings
          ci_cd_settings.pipeline_variables_minimum_override_role = project_minimum_role
          ci_cd_settings.restrict_user_defined_variables = from_value
          ci_cd_settings.save!
        end

        it 'allows/disallows to change restrict_user_defined_variables' do
          result = update_project(project, current_user, restrict_user_defined_variables: to_value)
          expect(result[:status]).to eq(status)
        end
      end
    end

    context 'when changing ci_pipeline_variables_minimum_override_role' do
      using RSpec::Parameterized::TableSyntax

      where(:current_user_role, :restrict_user_defined_variables, :from_value, :to_value, :status) do
        :owner      | true  | :owner      | :developer  | :success
        :owner      | true  | :owner      | :maintainer | :success
        :owner      | true  | :developer  | :maintainer | :success
        :owner      | true  | :maintainer | :owner      | :success
        :maintainer | true  | :owner      | :developer  | :api_error
        :maintainer | true  | :owner      | :maintainer | :api_error
        :maintainer | true  | :developer  | :maintainer | :success
        :maintainer | true  | :maintainer | :owner      | :api_error
        :owner      | false | :owner      | :maintainer | :success
        :maintainer | false | :owner      | :developer  | :api_error
        :maintainer | false | :maintainer | :owner      | :api_error
      end

      with_them do
        let(:current_user) { public_send(current_user_role) }

        before do
          project.add_maintainer(maintainer)
          project.add_developer(developer)
          project.add_owner(owner)

          ci_cd_settings = project.ci_cd_settings
          ci_cd_settings.pipeline_variables_minimum_override_role = from_value
          ci_cd_settings.restrict_user_defined_variables = restrict_user_defined_variables
          ci_cd_settings.save!
        end

        it 'allows/disallows to change ci_pipeline_variables_minimum_override_role' do
          result = update_project(project, current_user, ci_pipeline_variables_minimum_override_role: to_value.to_s)
          expect(result[:status]).to eq(status)
        end
      end
    end

    context 'when changing visibility level' do
      it_behaves_like 'publishing Projects::ProjectAttributesChangedEvent',
        params: { visibility_level: Gitlab::VisibilityLevel::INTERNAL },
        attributes: %w[updated_at visibility_level]

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

      context 'when user is not project owner' do
        let_it_be(:maintainer) { create(:user) }

        before do
          project.add_maintainer(maintainer)
        end

        context 'when project is private' do
          it 'does not update the project to public' do
            result = update_project(project, maintainer, visibility_level: Gitlab::VisibilityLevel::PUBLIC)

            expect(result).to eq({ status: :error, message: 'New visibility level not allowed!' })
            expect(project).to be_private
          end

          it 'does not update the project to public with tricky value' do
            result = update_project(project, maintainer, visibility_level: Gitlab::VisibilityLevel::PUBLIC.to_s + 'r')

            expect(result).to eq({ status: :error, message: 'New visibility level not allowed!' })
            expect(project).to be_private
          end
        end

        context 'when project is public' do
          before do
            project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          end

          it 'does not update the project to private' do
            result = update_project(project, maintainer, visibility_level: Gitlab::VisibilityLevel::PRIVATE)

            expect(result).to eq({ status: :error, message: 'New visibility level not allowed!' })
            expect(project).to be_public
          end

          it 'does not update the project to private with invalid string value' do
            result = update_project(project, maintainer, visibility_level: 'invalid')

            expect(result).to eq({ status: :error, message: 'New visibility level not allowed!' })
            expect(project).to be_public
          end

          it 'does not update the project to private with valid string value' do
            result = update_project(project, maintainer, visibility_level: 'private')

            expect(result).to eq({ status: :error, message: 'New visibility level not allowed!' })
            expect(project).to be_public
          end

          # See https://gitlab.com/gitlab-org/gitlab/-/issues/359910
          it 'does not update the project to private because of Active Record typecasting' do
            result = update_project(project, maintainer, visibility_level: 'public')

            expect(result).to eq({ status: :success })
            expect(project).to be_public
          end
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
      let(:user) { project.first_owner }
      let(:forked_project) { fork_project(project) }

      it 'does not change visibility of forks' do
        opts = { visibility_level: Gitlab::VisibilityLevel::PRIVATE }

        expect(project).to be_internal
        expect(forked_project).to be_internal

        expect(update_project(project, user, opts)).to eq({ status: :success })

        expect(project).to be_private
        expect(forked_project.reload).to be_internal
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

      context 'when repository has an ambiguous branch named "HEAD"' do
        before do
          allow(project.repository.raw).to receive(:write_ref).and_return(false)
          allow(project.repository).to receive(:branch_names) { %w[fix master main HEAD] }
        end

        it 'returns an error to the user' do
          result = update_project(project, admin, default_branch: 'fix')

          expect(result).to include(status: :error)
          expect(result[:message]).to include("Could not set the default branch. Do you have a branch named 'HEAD' in your repository?")

          project.reload

          expect(project.default_branch).to eq 'master'
          expect(project.previous_default_branch).to be_nil
        end
      end
    end

    context 'when we update project but not enabling a wiki' do
      it 'does not try to create an empty wiki' do
        project.wiki.repository.raw.remove

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
        project.wiki.repository.raw.remove

        result = update_project(project, user, project_feature_attributes: { wiki_access_level: ProjectFeature::ENABLED })

        expect(result).to eq({ status: :success })
        expect(project.wiki_repository_exists?).to be true
        expect(project.wiki_enabled?).to be true
      end

      it 'logs an error and creates a metric when wiki can not be created' do
        project.project_feature.update!(wiki_access_level: ProjectFeature::DISABLED)

        expect_next_instance_of(ProjectWiki) do |project_wiki|
          expect(project_wiki).to receive(:create_wiki_repository).and_raise(Wiki::CouldNotCreateWikiError)
        end
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

    context 'when changes project features' do
      # Using some sample features for testing.
      # Not using all the features because some of them must be enabled/disabled together
      %w[issues wiki forking model_experiments model_registry].each do |feature_name|
        context "with feature_name:#{feature_name}" do
          let(:feature) { "#{feature_name}_access_level" }
          let(:params) do
            { project_feature_attributes: { feature => ProjectFeature::ENABLED } }
          end

          before do
            project.project_feature.update!(feature => ProjectFeature::DISABLED)
          end

          it 'publishes Projects::ProjectFeaturesChangedEvent' do
            expect { update_project(project, user, params) }
              .to publish_event(Projects::ProjectFeaturesChangedEvent)
              .with(
                project_id: project.id,
                namespace_id: project.namespace_id,
                root_namespace_id: project.root_namespace.id,
                features: array_including(feature, "updated_at")
              )
          end
        end
      end
    end

    context 'when archiving a project' do
      it_behaves_like 'publishing Projects::ProjectAttributesChangedEvent',
        params: { archived: true },
        attributes: %w[updated_at archived]

      it 'publishes a ProjectTransferedEvent' do
        expect { update_project(project, user, archived: true) }
          .to publish_event(Projects::ProjectArchivedEvent)
          .with(
            project_id: project.id,
            namespace_id: project.namespace_id,
            root_namespace_id: project.root_namespace.id
          )
      end
    end

    context 'when changing operations feature visibility' do
      let(:feature_params) { { operations_access_level: ProjectFeature::DISABLED } }

      it 'does not sync the changes to the related fields' do
        result = update_project(project, user, project_feature_attributes: feature_params)

        expect(result).to eq({ status: :success })
        feature = project.project_feature

        expect(feature.operations_access_level).to eq(ProjectFeature::DISABLED)
        expect(feature.monitor_access_level).not_to eq(ProjectFeature::DISABLED)
        expect(feature.infrastructure_access_level).not_to eq(ProjectFeature::DISABLED)
        expect(feature.feature_flags_access_level).not_to eq(ProjectFeature::DISABLED)
        expect(feature.environments_access_level).not_to eq(ProjectFeature::DISABLED)
      end
    end

    context 'when updating a project that contains container images' do
      let(:new_name) { 'renamed' }

      before do
        stub_container_registry_config(enabled: true)
        stub_container_registry_tags(repository: /image/, tags: %w[rc1])
        create(:container_repository, project: project, name: :image)
      end

      shared_examples 'renaming the project fails with message' do |error_message|
        it 'does not allow to rename the project' do
          result = update_project(project, admin, path: new_name)

          expect(result).to include(status: :error)
          expect(result[:message]).to match(error_message)
        end
      end

      context 'when the GitlabAPI is not supported' do
        before do
          allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(false)
        end

        it_behaves_like 'renaming the project fails with message', /contains container registry tags/
      end

      context 'when Gitlab API is supported' do
        before do
          allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(true)
        end

        it 'executes a dry run of the project rename' do
          stub_rename_base_repository_in_registry(dry_run: true)

          update_project(project, admin, path: new_name)

          expect_rename_of_base_repository_in_registry(dry_run: true)
        end

        context 'when the dry run fails' do
          before do
            stub_rename_base_repository_in_registry(dry_run: true, result: :bad_request)
          end

          it_behaves_like 'renaming the project fails with message', /container registry path rename validation failed/

          it 'logs the error' do
            expect_any_instance_of(described_class).to receive(:log_error).with("Dry run failed for renaming project with tags: #{project.full_path}, error: bad_request")

            update_project(project, admin, path: new_name)
          end
        end

        context 'when the dry run succeeds' do
          before do
            stub_rename_base_repository_in_registry(dry_run: true, result: :accepted)
          end

          it 'continues with the project rename' do
            stub_rename_base_repository_in_registry(dry_run: false, result: :ok)
            old_project_full_path = project.full_path

            update_project(project, admin, path: new_name)

            expect_rename_of_base_repository_in_registry(dry_run: true, path: old_project_full_path)
            expect_rename_of_base_repository_in_registry(dry_run: false, path: old_project_full_path)
          end
        end

        def stub_rename_base_repository_in_registry(dry_run:, result: nil)
          options = { name: new_name }
          options[:dry_run] = true if dry_run

          allow(ContainerRegistry::GitlabApiClient)
            .to receive(:rename_base_repository_path)
            .with(project.full_path, options)
            .and_return(result)
        end

        def expect_rename_of_base_repository_in_registry(dry_run:, path: nil)
          options = { name: new_name }
          options[:dry_run] = true if dry_run

          expect(ContainerRegistry::GitlabApiClient)
            .to have_received(:rename_base_repository_path)
            .with(path || project.full_path, options)
        end
      end

      it 'allows to update other settings' do
        result = update_project(project, admin, public_builds: true)

        expect(result[:status]).to eq :success
        expect(project.reload.public_builds).to be true
      end
    end

    context 'when renaming a project' do
      let(:raw_fake_repo) { Gitlab::Git::Repository.new('default', File.join(user.namespace.full_path, 'existing.git'), nil, nil) }

      context 'with legacy storage' do
        let(:project) { create(:project, :legacy_storage, :repository, creator: user, namespace: user.namespace) }

        before do
          raw_fake_repo.create_repository
        end

        after do
          raw_fake_repo.remove
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
          message: "Name can contain only letters, digits, emoji, '_', '.', '+', dashes, or spaces. It must start with a letter, digit, emoji, or '_'."
        })
      end
    end

    context 'when updating #emails_enabled' do
      it 'updates the attribute for the project owner' do
        expect { update_project(project, user, emails_enabled: false) }
          .to change { project.emails_enabled }
          .to(false)
      end

      it 'does not update when not project owner' do
        maintainer = create(:user)
        project.add_member(maintainer, :maintainer)

        expect { update_project(project, maintainer, emails_enabled: false) }
          .not_to change { project.emails_enabled }
      end
    end

    context 'when updating #max_artifacts_size' do
      context 'for users who have the ability to update max_artifacts_size', :enable_admin_mode do
        let(:admin_user) { create(:admin) }

        it 'updates max_artifacts_size' do
          expect { update_project(project, admin_user, max_artifacts_size: 10) }
            .to change { project.max_artifacts_size }
                  .to(10)
        end
      end

      context 'for users who do not have the ability to update max_artifacts_size' do
        it 'does not update max_artifacts_size' do
          maintainer = create(:user)
          project.add_member(maintainer, :maintainer)

          expect { update_project(project, maintainer, max_artifacts_size: 10) }
            .not_to change { project.max_artifacts_size }
        end
      end
    end

    context 'when updating #runner_registration_enabled' do
      it 'updates the attribute' do
        expect { update_project(project, user, runner_registration_enabled: false) }
          .to change { project.runner_registration_enabled }
          .to(false)
      end

      context 'when runner registration is disabled for all projects' do
        before do
          stub_application_setting(valid_runner_registrars: [])
        end

        it 'restricts updating the attribute' do
          expect { update_project(project, user, runner_registration_enabled: false) }
            .not_to change { project.runner_registration_enabled }
        end
      end
    end

    context 'when updating runners settings' do
      let(:settings) do
        { instance_runners_enabled: true, namespace_traversal_ids: [123] }
      end

      let!(:pending_build) do
        create(:ci_pending_build, project: project, **settings)
      end

      context 'when project has shared runners enabled' do
        let(:project) { create(:project, shared_runners_enabled: true) }

        it 'updates builds queue when shared runners get disabled' do
          expect { update_project(project, admin, shared_runners_enabled: false) }
            .to change { pending_build.reload.instance_runners_enabled }.to(false)

          expect(pending_build.reload.instance_runners_enabled).to be false
        end
      end

      context 'when project has shared runners disabled' do
        let(:project) { create(:project, shared_runners_enabled: false) }

        it 'updates builds queue when shared runners get enabled' do
          expect { update_project(project, admin, shared_runners_enabled: true) }
            .to not_change { pending_build.reload.instance_runners_enabled }

          expect(pending_build.reload.instance_runners_enabled).to be true
        end
      end

      context 'when project has group runners enabled' do
        let(:project) { create(:project, group_runners_enabled: true) }

        before do
          project.ci_cd_settings.update!(group_runners_enabled: true)
        end

        it 'updates builds queue when group runners get disabled' do
          update_project(project, admin, group_runners_enabled: false)

          expect(pending_build.reload.namespace_traversal_ids).to be_empty
        end
      end

      context 'when project has group runners disabled' do
        let(:project) { create(:project, :in_subgroup, group_runners_enabled: false) }

        before do
          project.reload.ci_cd_settings.update!(group_runners_enabled: false)
        end

        it 'updates builds queue when group runners get enabled' do
          update_project(project, admin, group_runners_enabled: true)

          expect(pending_build.reload.namespace_traversal_ids).to include(project.namespace.id)
        end
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

        expect(project.reload.external_authorization_classification_label).to eq('default_label')
      end

      it 'does not check the label when it does not change' do
        expect(::Gitlab::ExternalAuthorization).to receive(:access_allowed?).once

        update_project(project, user, { name: 'New name' })
      end
    end

    context 'when updating nested attributes for prometheus integration' do
      context 'prometheus integration exists' do
        let(:prometheus_integration_attributes) do
          attributes_for(
            :prometheus_integration,
            project: project,
            properties: { api_url: "http://new.prometheus.com", manual_configuration: "0" }
          )
        end

        let!(:prometheus_integration) do
          create(
            :prometheus_integration,
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
            attributes_for(
              :prometheus_integration,
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
            attributes_for(
              :prometheus_integration,
              project: project,
              properties: { api_url: 'invalid-url', manual_configuration: "1" }
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
        stub_storage_settings('test_second_storage' => {})
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

    describe 'when updating pages unique domain', feature_category: :pages do
      before do
        stub_pages_setting(enabled: true)
      end

      context 'when turning it on' do
        it 'adds pages unique domain' do
          expect(Gitlab::Pages).to receive(:add_unique_domain_to)

          expect { update_project(project, user, project_setting_attributes: { pages_unique_domain_enabled: true }) }
            .to change { project.project_setting.pages_unique_domain_enabled }
            .from(false).to(true)
        end
      end

      context 'when turning it off' do
        it 'adds pages unique domain' do
          expect(Gitlab::Pages).not_to receive(:add_unique_domain_to)

          expect { update_project(project, user, project_setting_attributes: { pages_unique_domain_enabled: false }) }
            .not_to change { project.project_setting.pages_unique_domain_enabled }
        end
      end
    end

    describe 'when updating pages primary domain', feature_category: :pages do
      let(:domain_present) { true }

      before do
        stub_pages_setting(enabled: true)
        allow(project).to receive(:pages_domain_present?).and_return(domain_present)
      end

      context 'when selecting an existing domain' do
        it 'updates the pages primary domain setting' do
          expect { update_project(project, user, project_setting_attributes: { pages_primary_domain: "http://example.com" }) }
            .to change { project.project_setting.pages_primary_domain }
                  .from(nil).to("http://example.com")
        end
      end

      context 'when clearing the primary domain' do
        let(:project_settings) { create(:project_setting, pages_primary_domain: "http://example.com") }
        let(:project) { build(:project, project_setting: project_settings) }

        it 'removes the pages primary domain setting' do
          expect(project.project_setting.pages_primary_domain).to eq("http://example.com")

          expect { update_project(project, user, project_setting_attributes: { pages_primary_domain: "" }) }
            .to change { project.project_setting.pages_primary_domain }
                  .from("http://example.com").to(nil)
        end
      end

      context 'when selecting a non-existing domain' do
        let(:domain_present) { false }

        it 'returns an error to the user' do
          result = update_project(project, user, project_setting_attributes: { pages_primary_domain: "http://example.com" })

          expect(result).to include(status: :error)
          expect(result[:message]).to include(_("The `pages_primary_domain` attribute is missing from the domain list in the Pages project configuration. Assign `pages_primary_domain` to the Pages project or reset it."))

          expect(project.project_setting.pages_primary_domain).to be_nil
        end
      end
    end

    describe 'when project has missing CI/CD settings record' do
      before do
        project.ci_cd_settings.destroy!
        project.reload
      end

      it 'does not fail and creates a ci_cd_settings record for the project' do
        result = update_project(project, user, topics: 'topics')
        expect(result[:status]).to eq(:success)

        expect(project.reload.ci_cd_settings).to be_present
      end
    end

    describe 'when updating ci_inbound_job_token_scope_enabled' do
      let(:category) { described_class }
      let(:user) { admin }

      subject(:service_action) { update_project(project, admin, ci_inbound_job_token_scope_enabled: ci_inbound_job_token_scope_enabled) }

      context 'when it is changed from false to true' do
        let(:ci_inbound_job_token_scope_enabled) { true }

        before do
          project.update!(ci_inbound_job_token_scope_enabled: false)
          project.reload
        end

        it 'updates the setting' do
          service_action
          expect(project.reload.ci_inbound_job_token_scope_enabled).to eq(true)
        end

        it_behaves_like 'internal event tracking' do
          let(:event) { 'enable_inbound_job_token_scope' }
        end
      end

      context 'when it is changed from true to false' do
        let(:ci_inbound_job_token_scope_enabled) { false }

        before do
          project.update!(ci_inbound_job_token_scope_enabled: true)
          project.reload
        end

        it 'updates the setting' do
          service_action
          expect(project.reload.ci_inbound_job_token_scope_enabled).to eq(false)
        end

        it_behaves_like 'internal event tracking' do
          let(:event) { 'disable_inbound_job_token_scope' }
        end
      end

      context 'when current value is true and is unchanged' do
        let(:ci_inbound_job_token_scope_enabled) { true }

        before do
          project.update!(ci_inbound_job_token_scope_enabled: true)
          project.reload
        end

        it 'does not trigger event' do
          expect { service_action }.not_to trigger_internal_events('enable_inbound_job_token_scope')
        end
      end

      context 'when current value is false and is unchanged' do
        let(:ci_inbound_job_token_scope_enabled) { false }

        before do
          project.update!(ci_inbound_job_token_scope_enabled: false)
          project.reload
        end

        it 'does not trigger event' do
          expect { service_action }.not_to trigger_internal_events('disable_inbound_job_token_scope')
        end
      end
    end
  end

  describe '#run_auto_devops_pipeline?' do
    subject { described_class.new(project, user).run_auto_devops_pipeline? }

    context 'when master contains a .gitlab-ci.yml file' do
      before do
        allow(project).to receive(:has_ci_config_file?).and_return(true)
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
