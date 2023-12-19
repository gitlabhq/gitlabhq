# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerPolicy, feature_category: :runner do
  let_it_be(:owner) { create(:user) }

  describe 'ability :read_runner' do
    let_it_be(:guest) { create(:user) }
    let_it_be(:reporter) { create(:user) }
    let_it_be(:developer) { create(:user) }
    let_it_be(:maintainer) { create(:user) }

    let_it_be_with_reload(:group) { create(:group, name: 'top-level', path: 'top-level') }
    let_it_be_with_reload(:subgroup) { create(:group, name: 'subgroup', path: 'subgroup', parent: group) }
    let_it_be_with_reload(:project) { create(:project, group: subgroup) }
    let_it_be_with_reload(:group_without_project) { create(:group, name: 'top-level2', path: 'top-level2') }

    let_it_be(:instance_runner) { create(:ci_runner, :instance) }
    let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }
    let_it_be(:subgroup_runner) { create(:ci_runner, :group, groups: [subgroup]) }
    let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }
    let_it_be(:runner_on_group_without_project) { create(:ci_runner, :group, groups: [group_without_project]) }

    subject(:policy) { described_class.new(user, runner) }

    before_all do
      group.add_guest(guest)
      group.add_reporter(reporter)
      group.add_developer(developer)
      group.add_maintainer(maintainer)
      group.add_owner(owner)
    end

    shared_examples 'a policy allowing reading instance runner depending on runner sharing' do
      context 'with instance runner' do
        using RSpec::Parameterized::TableSyntax

        where(:shared_runners_enabled_on_group, :shared_runners_enabled_on_project, :expect_can_read) do
          false  | false  | false
          false  | true   | true
          true   | false  | true
          true   | true   | true
        end

        with_them do
          let(:runner) { instance_runner }

          before do
            group.update!(shared_runners_enabled: shared_runners_enabled_on_group)
            project.update!(shared_runners_enabled: shared_runners_enabled_on_project)
          end

          specify do
            if expect_can_read
              expect_allowed :read_runner
            else
              expect_disallowed :read_runner
            end
          end
        end
      end
    end

    shared_examples 'a policy allowing reading group runner depending on runner sharing' do |user_role|
      let(:group_runners_enabled_on_project) { true }

      before do
        project.update!(group_runners_enabled: group_runners_enabled_on_project)
      end

      context 'with group runner' do
        let(:runner) { group_runner }

        # NOTE: The user is allowed to read the runner because:
        # - the user is a developer+ in the runner's group
        # - the user is a developer+ in `group/subgroup/project`, and the runner is shared to that project
        it { expect_allowed :read_runner }

        context 'with sharing of group runners disabled' do
          let(:group_runners_enabled_on_project) { false }

          it { expect_allowed :read_runner }
        end

        context 'when user belongs to subgroup only' do
          let_it_be(:subgroup_member) do
            create(:user).tap { |subgroup_member| subgroup.add_member(subgroup_member, user_role) }
          end

          let(:user) { subgroup_member }

          context 'with runner visible to group project' do
            # NOTE: The user is allowed to read the runner because the user is a developer+ in `group/subgroup/project`,
            # and the runner is shared to that project
            it { expect_allowed :read_runner }

            context 'with sharing of group runners disabled' do
              let(:group_runners_enabled_on_project) { false }

              it { expect_disallowed :read_runner }
            end
          end

          context 'without projects in group' do
            let(:runner) { runner_on_group_without_project }

            it { expect_disallowed :read_runner }
          end
        end

        context "when user is not #{user_role} in associated group" do
          let_it_be(:user_with_role) { create(:user) }

          let(:user) { user_with_role }

          it { expect_disallowed :read_runner }

          context "when user is #{user_role} in a group invited to group as #{user_role}" do
            let_it_be(:invited_group) { create(:group, name: "#{user_role}s", path: "#{user_role}s") }

            before_all do
              invited_group.add_member(user_with_role, user_role)
              create(:group_group_link, :developer, shared_group: group, shared_with_group: invited_group)
            end

            it { expect_allowed :read_runner }
          end

          context "when user is a reporter in a group invited to group as #{user_role}" do
            let_it_be(:invited_group) { create(:group, name: "#{user_role}s", path: "#{user_role}s") }

            before_all do
              invited_group.add_reporter(user_with_role)
              create(:group_group_link, user_role, shared_group: group, shared_with_group: invited_group)
            end

            it { expect_disallowed :read_runner }
          end
        end
      end

      context 'when runner is in subgroup' do
        let(:runner) { subgroup_runner }

        # NOTE: The user is allowed to read the runner because the user is a developer+ in `group/subgroup/project`,
        # and the runner is shared to that project
        it { expect_allowed :read_runner }

        context 'with sharing of group runners disabled' do
          let(:group_runners_enabled_on_project) { false }

          it { expect_disallowed :read_runner }
        end
      end
    end

    shared_examples 'does not allow reading runners on any scope' do
      context 'with instance runner' do
        let(:runner) { instance_runner }

        it { expect_disallowed :read_runner }

        context 'with shared runners disabled for groups and projects' do
          before do
            group.update!(shared_runners_enabled: false)
            project.update!(shared_runners_enabled: false)
          end

          it { expect_disallowed :read_runner }
        end
      end

      context 'with group runner' do
        let(:runner) { group_runner }

        it { expect_disallowed :read_runner }

        context 'with group invited as maintainer to group containing runner' do
          let_it_be(:invited_group) { create(:group) }
          let_it_be(:runner) { create(:ci_runner, :group, groups: [invited_group]) }

          before_all do
            create(:group_group_link, :maintainer, shared_group: group, shared_with_group: invited_group)
          end

          it { expect_disallowed :read_runner }
        end

        context 'with sharing of group runners disabled' do
          before do
            project.update!(group_runners_enabled: false)
          end

          it { expect_disallowed :read_runner }
        end
      end

      context 'with project runner' do
        let(:runner) { project_runner }

        it { expect_disallowed :read_runner }
      end
    end

    context 'without access' do
      let_it_be(:user) { create(:user) }

      it_behaves_like 'does not allow reading runners on any scope'
    end

    context 'with guest access' do
      let(:user) { guest }

      it_behaves_like 'does not allow reading runners on any scope'
    end

    context 'with reporter access' do
      let(:user) { reporter }

      it_behaves_like 'does not allow reading runners on any scope'
    end

    context 'with developer access' do
      let(:user) { developer }

      it_behaves_like 'a policy allowing reading instance runner depending on runner sharing'

      it_behaves_like 'a policy allowing reading group runner depending on runner sharing', :developer

      context 'with project runner' do
        let(:runner) { project_runner }

        it { expect_allowed :read_runner }

        context 'when user is not developer in parent group' do
          let_it_be(:developers_group_developer) { create(:user) }
          let_it_be_with_reload(:developers_group) { create(:group, name: 'developers', path: 'developers') }

          let(:user) { developers_group_developer }

          before_all do
            create(:project_group_link, :developer, group: developers_group, project: project)
            developers_group.add_reporter(developers_group_developer)
          end

          it { expect_disallowed :read_runner }

          context 'when user is developer in a group invited to project as developer' do
            before_all do
              developers_group.add_developer(developers_group_developer)
            end

            it { expect_allowed :read_runner }
          end
        end
      end
    end

    context 'with maintainer access' do
      let(:user) { maintainer }

      it_behaves_like 'a policy allowing reading instance runner depending on runner sharing'

      it_behaves_like 'a policy allowing reading group runner depending on runner sharing', :maintainer

      context 'with project runner' do
        let(:runner) { project_runner }

        it { expect_allowed :read_runner }
      end
    end

    context 'with owner access' do
      let(:user) { owner }

      it_behaves_like 'a policy allowing reading instance runner depending on runner sharing'

      context 'with group runner' do
        let(:runner) { group_runner }

        it { expect_allowed :read_runner }

        context 'with sharing of group runners disabled' do
          before do
            project.update!(group_runners_enabled: false)
          end

          it { expect_allowed :read_runner }
        end
      end

      context 'with project runner' do
        let(:runner) { project_runner }

        it { expect_allowed :read_runner }
      end
    end
  end

  describe 'ability :read_ephemeral_token' do
    subject(:policy) { described_class.new(user, runner) }

    let_it_be(:runner) { create(:ci_runner, creator: owner) }

    let(:creator) { owner }

    context 'with request made by creator' do
      let(:user) { creator }

      it { expect_allowed :read_ephemeral_token }
    end

    context 'with request made by another user' do
      let(:user) { create(:admin) }

      it { expect_disallowed :read_ephemeral_token }
    end
  end
end
