# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildPolicy do
  let(:user) { create(:user) }
  let(:build) { create(:ci_build, pipeline: pipeline) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

  let(:policy) do
    described_class.new(user, build)
  end

  shared_context 'public pipelines disabled' do
    before do
      project.update_attribute(:public_builds, false)
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
        let(:owner) { user }

        it 'enables update_build if user is maintainer' do
          allow_any_instance_of(Project).to receive(:empty_repo?).and_return(false)
          allow_any_instance_of(Project).to receive(:branch_allows_collaboration?).and_return(true)

          expect(policy).to be_allowed :update_build
          expect(policy).to be_allowed :update_commit_status
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
          create(:protected_branch, :no_one_can_push,
                 name: build.ref, project: project)
        end

        it 'does not include ability to update build' do
          expect(policy).to be_disallowed :update_build
        end
      end

      context 'when developers can push to the branch' do
        before do
          create(:protected_branch, :developers_can_merge,
                 name: build.ref, project: project)
        end

        it 'includes ability to update build' do
          expect(policy).to be_allowed :update_build
        end
      end

      context 'when no one can create the tag' do
        before do
          create(:protected_tag, :no_one_can_create,
                 name: build.ref, project: project)

          build.update!(tag: true)
        end

        it 'does not include ability to update build' do
          expect(policy).to be_disallowed :update_build
        end
      end

      context 'when no one can create the tag but it is not a tag' do
        before do
          create(:protected_tag, :no_one_can_create,
                 name: build.ref, project: project)
        end

        it 'includes ability to update build' do
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
                create(:protected_branch, :developers_can_push,
                       name: build.ref, project: project)
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
            create(:protected_branch, :no_one_can_push, :no_one_can_merge,
                   name: build.ref, project: project)
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
            create(:protected_branch, :maintainers_can_push,
                   name: build.ref, project: project)
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
            create(:protected_branch, :no_one_can_push, :no_one_can_merge,
                   name: build.ref, project: project)
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
            create(:protected_branch, :developers_can_push,
                   name: build.ref, project: project)
          end

          it { expect(policy).to be_allowed :erase_build }
        end

        context 'when the build was created for a protected tag' do
          before do
            create(:protected_tag, :developers_can_create,
                   name: build.ref, project: project)
          end

          it { expect(policy).to be_allowed :erase_build }
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
end
