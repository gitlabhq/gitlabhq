# frozen_string_literal: true

RSpec.shared_examples 'a policy allowing reading instance runner/runner manager depending on runner sharing' do
    |ability|
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
          expect_allowed ability
        else
          expect_disallowed ability
        end
      end
    end
  end
end

RSpec.shared_examples 'a policy allowing reading group runner/runner manager depending on runner sharing' do
    |ability, user_role|
  let(:group_runners_enabled_on_project) { true }

  before do
    project.update!(group_runners_enabled: group_runners_enabled_on_project)
  end

  context 'with group runner' do
    let(:runner) { group_runner }

    # NOTE: The user is allowed to read the runner/runner manager because:
    # - the user is a maintainer+ in the runner's group
    # - the user is a maintainer+ in `group/subgroup/project`, and the runner is shared to that project
    it { expect_allowed ability }

    context 'with sharing of group runners disabled' do
      let(:group_runners_enabled_on_project) { false }

      it { expect_allowed ability }
    end

    context 'when user belongs to subgroup only' do
      let_it_be(:subgroup_member) do
        create(:user).tap { |subgroup_member| subgroup.add_member(subgroup_member, user_role) }
      end

      let(:user) { subgroup_member }

      context 'with runner visible to group project' do
        # NOTE: The user is allowed to read the runner/runner manager because the user is a maintainer+
        # in `group/subgroup/project`, and the runner is shared to that project
        it { expect_allowed ability }

        context 'with sharing of group runners disabled' do
          let(:group_runners_enabled_on_project) { false }

          it { expect_disallowed ability }
        end
      end

      context 'without projects in group' do
        let(:runner) { runner_on_group_without_project }

        it { expect_disallowed ability }
      end
    end

    context "when user is not #{user_role} in associated group" do
      let_it_be(:user_with_role) { create(:user) }

      let(:user) { user_with_role }

      it { expect_disallowed ability }

      context "when user is #{user_role} in a group invited to group as #{user_role}" do
        let_it_be(:invited_group) { create(:group, name: "#{user_role}s", path: "#{user_role}s") }

        before_all do
          invited_group.add_member(user_with_role, user_role)
          create(:group_group_link, :maintainer, shared_group: group, shared_with_group: invited_group)
        end

        it { expect_allowed ability }
      end

      context "when user is a reporter in a group invited to group as #{user_role}" do
        let_it_be(:invited_group) do
          create(:group, name: "#{user_role}s", path: "#{user_role}s", reporters: user_with_role)
        end

        before_all do
          create(:group_group_link, user_role, shared_group: group, shared_with_group: invited_group)
        end

        it { expect_disallowed ability }
      end
    end
  end

  context 'when runner is in subgroup' do
    let(:runner) { subgroup_runner }

    # NOTE: The user is allowed to read the runner/runner manager because the user is a maintainer+ in
    # `group/subgroup/project`, and the runner is shared to that project
    it { expect_allowed ability }

    context 'with sharing of group runners disabled' do
      let(:group_runners_enabled_on_project) { false }

      it { expect_disallowed ability }
    end
  end
end

RSpec.shared_examples 'does not allow reading runners/runner managers on any scope' do |ability|
  context 'with instance runner' do
    let(:runner) { instance_runner }

    it { expect_disallowed ability }

    context 'with shared runners disabled for groups and projects' do
      before do
        group.update!(shared_runners_enabled: false)
        project.update!(shared_runners_enabled: false)
      end

      it { expect_disallowed ability }
    end
  end

  context 'with group runner' do
    let(:runner) { group_runner }

    it { expect_disallowed ability }

    context 'with group invited as maintainer to group containing runner' do
      let_it_be(:invited_group) { create(:group) }
      let_it_be(:runner) { create(:ci_runner, :group, :with_runner_manager, groups: [invited_group]) }

      before_all do
        create(:group_group_link, :maintainer, shared_group: group, shared_with_group: invited_group)
      end

      it { expect_disallowed ability }
    end

    context 'with sharing of group runners disabled' do
      before do
        project.update!(group_runners_enabled: false)
      end

      it { expect_disallowed ability }
    end
  end

  context 'with project runner' do
    let(:runner) { project_runner }

    it { expect_disallowed ability }
  end
end

RSpec.shared_examples 'runner read policy' do |ability|
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }

  let_it_be_with_reload(:group) do
    create(:group, name: 'top-level', path: 'top-level',
      guests: guest, reporters: reporter, developers: developer, maintainers: maintainer, owners: owner)
  end

  let_it_be_with_reload(:subgroup) { create(:group, name: 'subgroup', path: 'subgroup', parent: group) }
  let_it_be_with_reload(:project) { create(:project, group: subgroup) }
  let_it_be_with_reload(:group_without_project) { create(:group, name: 'top-level2', path: 'top-level2') }

  let_it_be(:instance_runner) { create(:ci_runner, :instance, :with_runner_manager) }
  let_it_be(:group_runner) { create(:ci_runner, :group, :with_runner_manager, groups: [group]) }
  let_it_be(:subgroup_runner) { create(:ci_runner, :group, :with_runner_manager, groups: [subgroup]) }
  let_it_be(:project_runner) { create(:ci_runner, :project, :with_runner_manager, projects: [project]) }
  let_it_be(:runner_on_group_without_project) do
    create(:ci_runner, :group, :with_runner_manager, groups: [group_without_project])
  end

  context 'without access' do
    let_it_be(:user) { create(:user) }

    it_behaves_like 'does not allow reading runners/runner managers on any scope', ability
  end

  context 'with guest access' do
    let(:user) { guest }

    it_behaves_like 'does not allow reading runners/runner managers on any scope', ability
  end

  context 'with reporter access' do
    let(:user) { reporter }

    it_behaves_like 'does not allow reading runners/runner managers on any scope', ability
  end

  context 'with developer access' do
    let(:user) { developer }

    it_behaves_like 'does not allow reading runners/runner managers on any scope', ability
  end

  context 'with maintainer access' do
    let(:user) { maintainer }

    it_behaves_like 'a policy allowing reading instance runner/runner manager depending on runner sharing', ability

    it_behaves_like 'a policy allowing reading group runner/runner manager depending on runner sharing',
      ability, :maintainer

    context 'with project runner' do
      let(:runner) { project_runner }

      it { expect_allowed ability }

      context 'when user is not maintainer in parent group' do
        let_it_be(:maintainers_group_maintainer) { create(:user) }
        let_it_be_with_reload(:maintainers_group) { create(:group, name: 'maintainers', path: 'maintainers') }

        let(:user) { maintainers_group_maintainer }

        before_all do
          create(:project_group_link, :maintainer, group: maintainers_group, project: project)
          maintainers_group.add_reporter(maintainers_group_maintainer)
        end

        it { expect_disallowed ability }

        context 'when user is maintainer in a group invited to project as maintainer' do
          before_all do
            maintainers_group.add_maintainer(maintainers_group_maintainer)
          end

          it { expect_allowed ability }
        end
      end
    end
  end

  context 'with owner access' do
    let(:user) { owner }

    it_behaves_like 'a policy allowing reading instance runner/runner manager depending on runner sharing', ability

    context 'with group runner' do
      let(:runner) { group_runner }

      it { expect_allowed ability }

      context 'with sharing of group runners disabled' do
        before do
          project.update!(group_runners_enabled: false)
        end

        it { expect_allowed ability }
      end
    end

    context 'with project runner' do
      let(:runner) { project_runner }

      it { expect_allowed ability }
    end
  end
end
