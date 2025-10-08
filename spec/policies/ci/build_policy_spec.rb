# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildPolicy, feature_category: :continuous_integration do
  let(:user) { create(:user) }
  let(:build) { create(:ci_build, pipeline: pipeline) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

  let(:policy) do
    described_class.new(user, build)
  end

  it_behaves_like 'a deployable job policy', :ci_build

  shared_context 'public pipelines disabled' do
    before do
      project.update_attribute(:public_builds, false)
    end
  end

  describe 'artifacts access config with access keyword' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:user) { create(:user) }

    include_context 'public pipelines disabled'

    before_all do
      project.add_developer(user)
    end

    context 'when job artifact access is set to all' do
      let(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

      it 'allows read_job_artifacts to project members' do
        expect(policy).to be_allowed :read_job_artifacts
      end
    end

    context 'when job artifact is private to developers' do
      let(:build) { create(:ci_build, :private_artifacts, pipeline: pipeline) }

      it 'allows read_job_artifacts to project members' do
        expect(policy).to be_allowed :read_job_artifacts
      end

      context 'when user is anon' do
        let(:user2) { create(:user) }

        let(:policy2) do
          described_class.new(user2, build)
        end

        it 'disallows read_job_artifacts to anon user' do
          expect(policy2).to be_disallowed :read_job_artifacts
        end
      end
    end

    context 'when job artifacts are restricted by different roles' do
      using RSpec::Parameterized::TableSyntax

      def user_for(role)
        user = create(:user)
        case role
        when :maintainer then project.add_maintainer(user)
        when :owner      then project.add_owner(user)
        when :developer  then project.add_developer(user)
        when :guest      then project.add_guest(user)
        end

        user
      end

      where(:artifact_trait, :config_build_access_trait, :role, :allowed) do
        # --- Maintainer-only access ---
        :artifacts           | :with_public_artifacts_config | :maintainer | true
        :artifacts           | :with_public_artifacts_config | :owner      | true
        :artifacts           | :with_public_artifacts_config | :developer  | true
        :artifacts           | :with_public_artifacts_config | :guest      | true

        # -- Some examples only-shows we honor the artifact access level --
        # -- Just to illustrate the logic: we respect only job_artifacts access level --
        :artifacts           | :with_none_access_artifacts   | :guest      | true

        :private_artifacts   | :with_private_artifacts_config | :maintainer | true
        :private_artifacts   | :with_private_artifacts_config | :owner      | true
        :private_artifacts   | :with_private_artifacts_config | :developer  | true
        :private_artifacts   | :with_private_artifacts_config | :guest      | false

        :private_artifacts   | :with_none_access_artifacts    | :developer  | true

        :no_access_artifacts | :with_none_access_artifacts | :maintainer | false
        :no_access_artifacts | :with_none_access_artifacts | :owner      | false
        :no_access_artifacts | :with_none_access_artifacts | :developer  | false
        :no_access_artifacts | :with_none_access_artifacts | :guest      | false

        :no_access_artifacts | :with_developer_access_artifacts | :developer | false

        :artifacts_with_maintainer_access | :with_maintainer_access_artifacts | :maintainer | true
        :artifacts_with_maintainer_access | :with_maintainer_access_artifacts | :owner      | true
        :artifacts_with_maintainer_access | :with_maintainer_access_artifacts | :developer  | false
        :artifacts_with_maintainer_access | :with_maintainer_access_artifacts | :guest      | false

        # -- We match developer access to private access level on job artifacts --
        :private_artifacts   | :with_developer_access_artifacts | :maintainer | true
        :private_artifacts   | :with_developer_access_artifacts | :owner      | true
        :private_artifacts   | :with_developer_access_artifacts | :developer  | true
        :private_artifacts   | :with_developer_access_artifacts | :guest      | false

        :no_access_artifacts | :with_none_access_artifacts | :maintainer | false
        :no_access_artifacts | :with_none_access_artifacts | :owner      | false
        :no_access_artifacts | :with_none_access_artifacts | :developer  | false
        :no_access_artifacts | :with_none_access_artifacts | :guest      | false

        :no_access_artifacts | :with_developer_access_artifacts | :developer | false
      end

      with_them do
        let(:user) { user_for(role) }
        let(:build)  { create(:ci_build, artifact_trait, config_build_access_trait, pipeline: pipeline, project: project) }
        let(:policy) { described_class.new(user, build) }

        it 'applies the expected permission' do
          expect(policy).to(allowed ? be_allowed(:read_job_artifacts) : be_disallowed(:read_job_artifacts))
        end
      end
    end

    context 'when job artifact access is set to none' do
      let(:build) { create(:ci_build, :no_access_artifacts, pipeline: pipeline) }

      it 'disallows read_job_artifacts to project members' do
        expect(policy).to be_disallowed :read_job_artifacts
      end
    end

    context 'when no job artifacts on the build' do
      let(:build) { create(:ci_build, pipeline: pipeline) }
      let_it_be(:user) { create(:user) }

      before_all do
        project.add_developer(user)
      end

      it 'allows read_job_artifacts to project members' do
        expect(policy).to be_allowed :read_job_artifacts
      end
    end
  end

  describe ':read_manual_variables' do
    context 'when project is public' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:user) { create(:user) }

      context 'when user is at least a developer' do
        before_all do
          project.add_developer(user)
        end

        it 'is allowed' do
          expect(policy).to be_allowed :read_manual_variables
        end
      end

      context 'when user is a developer or below' do
        before_all do
          project.add_guest(user)
        end

        it 'is not allowed' do
          expect(policy).not_to be_allowed :read_manual_variables
        end
      end
    end

    context 'when project is internal' do
      let_it_be(:project) { create(:project, :internal) }

      context 'when user is an explicit member of the project' do
        let_it_be(:user) { create(:user) }

        before_all do
          project.add_guest(user)
        end

        it 'is allowed' do
          expect(policy).to be_allowed :read_manual_variables
        end
      end

      context 'when user is not a member of the project but has implicit guest access' do
        let(:user) { create(:user) }

        it 'is not allowed' do
          expect(policy).not_to be_allowed :read_manual_variables
        end
      end
    end

    context 'when project is private' do
      let_it_be(:project) { create(:project, :private) }
      let_it_be(:user) { create(:user) }

      context 'when user is a guest and a member of the project' do
        before_all do
          project.add_guest(user)
        end

        it 'is allowed' do
          expect(policy).to be_allowed :read_manual_variables
        end
      end

      context 'when user is not a member of the project' do
        let(:user) { create(:user) }

        it 'is not allowed' do
          expect(policy).not_to be_allowed :read_manual_variables
        end
      end
    end
  end

  describe '#rules' do
    context 'when user does not have access to the project' do
      let(:project) { create(:project, :private) }

      context 'when public builds are enabled' do
        it 'does not include ability to read build' do
          expect(policy).not_to be_allowed :read_build
        end
      end

      context 'when public builds are disabled' do
        include_context 'public pipelines disabled'

        it 'does not include ability to read build' do
          expect(policy).not_to be_allowed :read_build
        end
      end
    end

    context 'when anonymous user has access to the project' do
      let(:project) { create(:project, :public) }

      context 'when public builds are enabled' do
        it 'includes ability to read build' do
          expect(policy).to be_allowed :read_build
        end
      end

      context 'when public builds are disabled' do
        include_context 'public pipelines disabled'

        it 'does not include ability to read build' do
          expect(policy).not_to be_allowed :read_build
        end
      end
    end

    context 'when team member has access to the project' do
      let(:project) { create(:project, :public) }

      context 'team member is a guest' do
        before do
          project.add_guest(user)
        end

        context 'when public builds are enabled' do
          it 'includes ability to read build' do
            expect(policy).to be_allowed :read_build
          end
        end

        context 'when public builds are disabled' do
          include_context 'public pipelines disabled'

          it 'does not include ability to read build' do
            expect(policy).not_to be_allowed :read_build
          end
        end
      end

      context 'team member is a reporter' do
        before do
          project.add_reporter(user)
        end

        context 'when public builds are enabled' do
          it 'includes ability to read build' do
            expect(policy).to be_allowed :read_build
          end
        end

        context 'when public builds are disabled' do
          include_context 'public pipelines disabled'

          it 'does not include ability to read build' do
            expect(policy).to be_allowed :read_build
          end
        end
      end

      context 'when maintainer is allowed to push to pipeline branch' do
        let(:project) { create(:project, :public) }

        before do
          project.add_maintainer(user)

          allow(project).to receive(:empty_repo?).and_return(false)
          allow(project).to receive(:branch_allows_collaboration?).and_return(true)
        end

        it 'enables updates if user is maintainer', :aggregate_failures do
          expect(policy).to be_allowed :cancel_build
          expect(policy).to be_allowed :update_build
        end
      end
    end

    describe 'rules for archived jobs' do
      let_it_be(:project, reload: true) { create(:project, :repository) }

      let(:build) { create(:ci_build, user: user, pipeline: pipeline, ref: 'feature') }

      before do
        project.add_developer(user)
      end

      context 'when job is not archived' do
        it 'allows update and cleanup job abilities' do
          described_class.all_job_update_abilities.each do |perm|
            expect(policy).to be_allowed(perm)
          end

          described_class.all_job_cleanup_abilities.each do |perm|
            expect(policy).to be_allowed(perm)
          end
        end
      end

      context 'when job is archived' do
        before do
          allow(build).to receive(:archived?).and_return(true)
        end

        it 'prevents user facing update job abilities while allowing cleanup job abilities' do
          described_class.job_user_facing_update_abilities.each do |perm|
            expect(policy).to be_disallowed(perm)
          end

          described_class.all_job_cleanup_abilities.each do |perm|
            expect(policy).to be_allowed(perm)
          end
        end
      end
    end

    describe 'rules for protected ref' do
      let(:project) { create(:project, :repository) }
      let(:build) { create(:ci_build, ref: 'some-ref', pipeline: pipeline) }

      before do
        project.add_developer(user)
      end

      context 'when no one can push or merge to the branch' do
        before do
          create(:protected_branch, :no_one_can_push, name: build.ref, project: project)
        end

        it 'does not include ability to update build' do
          expect(policy).to be_disallowed :cancel_build
          expect(policy).to be_disallowed :update_build
        end

        context 'when the user is admin', :enable_admin_mode do
          before do
            user.update!(admin: true)
          end

          it 'does not include ability to update build' do
            expect(policy).to be_disallowed :cancel_build
            expect(policy).to be_disallowed :update_build
          end
        end
      end

      context 'when developers can push to the branch' do
        before do
          create(:protected_branch, :developers_can_merge, name: build.ref, project: project)
        end

        it 'includes ability to update build' do
          expect(policy).to be_allowed :cancel_build
          expect(policy).to be_allowed :update_build
        end
      end

      context 'when no one can create the tag' do
        before do
          create(:protected_tag, :no_one_can_create, name: build.ref, project: project)

          build.update!(tag: true)
        end

        it 'does not include ability to update build' do
          expect(policy).to be_disallowed :cancel_build
          expect(policy).to be_disallowed :update_build
        end
      end

      context 'when no one can create the tag but it is not a tag' do
        before do
          create(:protected_tag, :no_one_can_create, name: build.ref, project: project)
        end

        it 'includes ability to update build' do
          expect(policy).to be_allowed :cancel_build
          expect(policy).to be_allowed :update_build
        end
      end
    end

    describe 'rules for erase build' do
      let(:project) { create(:project, :repository) }
      let(:build) { create(:ci_build, pipeline: pipeline, ref: 'some-ref', user: owner) }

      context 'when a developer erases a build' do
        before do
          project.add_developer(user)
        end

        context 'when developers can push to the branch' do
          context 'when the build was created by the developer' do
            let(:owner) { user }

            context 'when the build was created for a protected ref' do
              before do
                create(:protected_branch, :developers_can_push, name: build.ref, project: project)
              end

              it { expect(policy).to be_disallowed :erase_build }
            end

            context 'when the build was created for an unprotected ref' do
              it { expect(policy).to be_allowed :erase_build }
            end
          end

          context 'when the build was created by the other' do
            let(:owner) { create(:user) }

            it { expect(policy).to be_disallowed :erase_build }
          end
        end

        context 'when no one can push or merge to the branch' do
          let(:owner) { user }

          before do
            create(:protected_branch, :no_one_can_push, :no_one_can_merge, name: build.ref, project: project)
          end

          it { expect(policy).to be_disallowed :erase_build }
        end
      end

      context 'when a maintainer erases a build' do
        before do
          project.add_maintainer(user)
        end

        context 'when maintainers can push to the branch' do
          before do
            create(:protected_branch, :maintainers_can_push, name: build.ref, project: project)
          end

          context 'when the build was created by the maintainer' do
            let(:owner) { user }

            it { expect(policy).to be_allowed :erase_build }
          end

          context 'when the build was created by the other' do
            let(:owner) { create(:user) }

            it { expect(policy).to be_allowed :erase_build }
          end
        end

        context 'when no one can push or merge to the branch' do
          let(:owner) { user }

          before do
            create(:protected_branch, :no_one_can_push, :no_one_can_merge, name: build.ref, project: project)
          end

          it { expect(policy).to be_disallowed :erase_build }
        end
      end

      context 'when an admin erases a build', :enable_admin_mode do
        let(:owner) { create(:user) }

        before do
          user.update!(admin: true)
        end

        context 'when the build was created for a protected branch' do
          before do
            create(:protected_branch, :developers_can_push, name: build.ref, project: project)
          end

          it { expect(policy).to be_disallowed :erase_build }
        end

        context 'when the build was created for a protected tag' do
          before do
            create(:protected_tag, :developers_can_create, name: build.ref, project: project)

            build.update!(tag: true)
          end

          it { expect(policy).to be_disallowed :erase_build }
        end

        context 'when the build was created for an unprotected ref' do
          it { expect(policy).to be_allowed :erase_build }
        end
      end
    end
  end

  describe 'manage a web ide terminal' do
    let(:build_permissions) { %i[read_web_ide_terminal create_build_terminal update_web_ide_terminal create_build_service_proxy] }
    let_it_be(:maintainer) { create(:user) }

    let(:owner) { create(:owner) }
    let(:admin) { create(:admin) }
    let(:maintainer) { create(:user) }
    let(:developer) { create(:user) }
    let(:reporter) { create(:user) }
    let(:guest) { create(:user) }
    let(:project) { create(:project, :public, namespace: owner.namespace) }
    let(:pipeline) { create(:ci_empty_pipeline, project: project, source: :webide) }
    let(:build) { create(:ci_build, pipeline: pipeline) }

    before do
      allow(build).to receive(:has_terminal?).and_return(true)

      project.add_maintainer(maintainer)
      project.add_developer(developer)
      project.add_reporter(reporter)
      project.add_guest(guest)
    end

    subject { described_class.new(current_user, build) }

    context 'when create_web_ide_terminal access enabled' do
      context 'with admin' do
        let(:current_user) { admin }

        context 'when admin mode enabled', :enable_admin_mode do
          it { expect_allowed(*build_permissions) }
        end

        context 'when admin mode disabled' do
          it { expect_disallowed(*build_permissions) }
        end

        context 'when build is not from a webide pipeline' do
          let(:pipeline) { create(:ci_empty_pipeline, project: project, source: :chat) }

          it { expect_disallowed(:read_web_ide_terminal, :update_web_ide_terminal, :create_build_service_proxy) }
        end

        context 'when build has no runner terminal' do
          before do
            allow(build).to receive(:has_terminal?).and_return(false)
          end

          context 'when admin mode enabled', :enable_admin_mode do
            it { expect_allowed(:read_web_ide_terminal, :update_web_ide_terminal) }
            it { expect_disallowed(:create_build_terminal, :create_build_service_proxy) }
          end

          context 'when admin mode disabled' do
            it { expect_disallowed(:read_web_ide_terminal, :update_web_ide_terminal) }
            it { expect_disallowed(:create_build_terminal, :create_build_service_proxy) }
          end
        end

        context 'feature flag "build_service_proxy" is disabled' do
          before do
            stub_feature_flags(build_service_proxy: false)
          end

          it { expect_disallowed(:create_build_service_proxy) }
        end
      end

      shared_examples 'allowed build owner access' do
        it { expect_disallowed(*build_permissions) }

        context 'when user is the owner of the job' do
          let(:build) { create(:ci_build, pipeline: pipeline, user: current_user) }

          it { expect_allowed(*build_permissions) }
        end
      end

      shared_examples 'forbidden access' do
        it { expect_disallowed(*build_permissions) }

        context 'when user is the owner of the job' do
          let(:build) { create(:ci_build, pipeline: pipeline, user: current_user) }

          it { expect_disallowed(*build_permissions) }
        end
      end

      context 'with owner' do
        let(:current_user) { owner }

        it_behaves_like 'allowed build owner access'
      end

      context 'with maintainer' do
        let(:current_user) { maintainer }

        it_behaves_like 'allowed build owner access'
      end

      context 'with developer' do
        let(:current_user) { developer }

        it_behaves_like 'forbidden access'
      end

      context 'with reporter' do
        let(:current_user) { reporter }

        it_behaves_like 'forbidden access'
      end

      context 'with guest' do
        let(:current_user) { guest }

        it_behaves_like 'forbidden access'
      end

      context 'with non member' do
        let(:current_user) { create(:user) }

        it_behaves_like 'forbidden access'
      end
    end
  end

  describe 'ability :create_build_terminal' do
    let(:project) { create(:project, :private) }

    subject { described_class.new(user, build) }

    context 'when user can update_build' do
      before do
        project.add_maintainer(user)
      end

      context 'when job has terminal' do
        before do
          allow(build).to receive(:has_terminal?).and_return(true)
        end

        context 'when current user is the job owner' do
          before do
            build.update!(user: user)
          end

          it { expect_allowed(:create_build_terminal) }
        end

        context 'when current user is not the job owner' do
          it { expect_disallowed(:create_build_terminal) }
        end
      end

      context 'when job does not have terminal' do
        before do
          allow(build).to receive(:has_terminal?).and_return(false)
          build.update!(user: user)
        end

        it { expect_disallowed(:create_build_terminal) }
      end
    end

    context 'when user cannot update build' do
      before do
        project.add_guest(user)
        allow(build).to receive(:has_terminal?).and_return(true)
      end

      it { expect_disallowed(:create_build_terminal) }
    end
  end
end
