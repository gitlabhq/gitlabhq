# frozen_string_literal: true

RSpec.shared_examples 'a policy allowing accessing group runner/runner manager depending on runner sharing' do
    |ability, user_role|
  let(:group_runners_enabled_on_project) { true }

  before do
    owner_project.update!(group_runners_enabled: group_runners_enabled_on_project)
  end

  context 'with group runner' do
    let(:runner) { group_runner }

    # NOTE: The user is allowed to access the runner/runner manager because:
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
        # NOTE: The user is allowed to access the runner/runner manager because the user is a maintainer+
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

    # NOTE: The user is allowed to access the runner/runner manager because the user is a maintainer+ in
    # `group/subgroup/project`, and the runner is shared to that project
    it { expect_allowed ability }

    context 'with sharing of group runners disabled' do
      let(:group_runners_enabled_on_project) { false }

      # NOTE: The user is allowed to access the runner/runner manager because the user is a maintainer+ in
      # `group`, and the runner is owned by a subgroup of that group
      it { expect_allowed ability }
    end
  end
end

RSpec.shared_examples 'does not allow accessing runners/runner managers on any scope' do |ability|
  context 'with instance runner' do
    let(:runner) { instance_runner }

    if ability.in?([:read_runner, :read_runner_manager])
      it { expect_allowed ability }
    else
      it { expect_disallowed ability }
    end

    context 'with shared runners disabled for groups and projects' do
      before do
        group.update!(shared_runners_enabled: false)
        owner_project.update!(shared_runners_enabled: false)
      end

      if ability.in?([:read_runner, :read_runner_manager])
        it { expect_allowed ability }
      else
        it { expect_disallowed ability }
      end
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
        owner_project.update!(group_runners_enabled: false)
      end

      it { expect_disallowed ability }
    end
  end

  context 'with project runner' do
    let(:runner) { project_runner }

    it { expect_disallowed ability }
  end
end

RSpec.shared_context 'with runner policy environment' do
  let_it_be_with_reload(:group) { create(:group, name: 'top-level', path: 'top-level', owners: owner) }
  let_it_be_with_reload(:subgroup) { create(:group, name: 'subgroup', path: 'subgroup', parent: group) }
  let_it_be_with_reload(:owner_project) { create(:project, group: subgroup) }
  let_it_be_with_reload(:other_project) { create(:project) }
  let_it_be_with_reload(:group_without_project) { create(:group, name: 'top-level2', path: 'top-level2') }

  let_it_be(:guest) { create(:user, guest_of: group) }
  let_it_be(:reporter) { create(:user, reporter_of: group) }
  let_it_be(:developer) { create(:user, developer_of: group) }
  let_it_be(:maintainer) { create(:user, maintainer_of: group) }

  let_it_be(:instance_runner) { create(:ci_runner, :instance, :with_runner_manager, creator: developer) }
  let_it_be(:group_runner) { create(:ci_runner, :group, :with_runner_manager, groups: [group]) }
  let_it_be(:subgroup_runner) { create(:ci_runner, :group, :with_runner_manager, groups: [subgroup]) }
  let_it_be(:project_runner) do
    create(:ci_runner, :project, :with_runner_manager, projects: [owner_project, other_project])
  end

  let_it_be(:runner_on_group_without_project) do
    create(:ci_runner, :group, :with_runner_manager, groups: [group_without_project])
  end
end

RSpec.shared_examples 'runner policy not allowed for levels lower than maintainer' do |ability|
  context 'without access' do
    let_it_be(:user) { create(:user) }

    it_behaves_like 'does not allow accessing runners/runner managers on any scope', ability
  end

  context 'with guest access' do
    let(:user) { guest }

    it_behaves_like 'does not allow accessing runners/runner managers on any scope', ability
  end

  context 'with reporter access' do
    let(:user) { reporter }

    it_behaves_like 'does not allow accessing runners/runner managers on any scope', ability
  end

  context 'with developer access' do
    let(:user) { developer }

    it_behaves_like 'does not allow accessing runners/runner managers on any scope', ability
  end
end

RSpec.shared_examples 'runner policy with project runner' do |ability|
  let(:runner) { project_runner }

  it { expect_allowed ability }

  context 'when user is developer in an associated project' do
    let_it_be(:user) { create(:user, developer_of: other_project) }

    it { expect_disallowed ability }
  end

  context 'when user is maintainer in an associated project' do
    let_it_be(:user) { create(:user, maintainer_of: other_project) }

    it { expect_allowed ability }
  end

  context 'when user is maintainer in an unrelated group' do
    let_it_be_with_refind(:maintainers_group_maintainer) { create(:user) }
    let_it_be_with_reload(:maintainers_group) do
      create(:group, name: 'maintainers', path: 'maintainers', maintainers: maintainers_group_maintainer)
    end

    let(:user) { maintainers_group_maintainer }

    it { expect_disallowed ability }

    context 'when maintainers group is invited as maintainer to project' do
      before do
        create(:project_group_link, :maintainer, group: maintainers_group, project: project_invited_to)
      end

      context 'and target project is owner project' do
        let(:project_invited_to) { owner_project }

        it { expect_allowed ability }
      end

      context 'and target project is other project' do
        let(:project_invited_to) { other_project }

        it { expect_allowed ability }
      end
    end
  end
end

RSpec.shared_examples 'runner policy for user with owner access' do
  |ability, scope: %i[instance_runner group_runner project_runner]|
  let(:user) { owner }

  if scope.include?(:instance_runner)
    context 'with instance runner' do
      let(:runner) { instance_runner }

      if ability.in?([:read_runner, :read_runner_manager])
        it { expect_allowed ability }
      else
        it { expect_disallowed ability }
      end
    end
  end

  if scope.include?(:group_runner)
    context 'with group runner' do
      let(:runner) { group_runner }

      it { expect_allowed ability }

      context 'with sharing of group runners disabled' do
        before do
          owner_project.update!(group_runners_enabled: false)
        end

        it { expect_allowed ability }
      end
    end
  end

  if scope.include?(:project_runner)
    context 'with project runner' do
      let(:runner) { project_runner }

      it { expect_allowed ability }
    end
  end
end

RSpec.shared_examples 'runner policy for admin user' do
  |ability, scope: %i[instance_runner group_runner project_runner]|
  let_it_be(:user) { create(:admin) }

  if scope.include?(:instance_runner)
    context 'with instance runner' do
      let(:runner) { instance_runner }

      if ability.in?([:read_runner, :read_runner_manager])
        it { expect_allowed ability }
      else
        it { expect_disallowed ability }
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it { expect_allowed ability }
      end
    end
  end

  if scope.include?(:group_runner)
    context 'with group runner' do
      let(:runner) { group_runner }

      it { expect_disallowed ability }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { expect_allowed ability }
      end
    end
  end

  if scope.include?(:project_runner)
    context 'with project runner' do
      let(:runner) { project_runner }

      it { expect_disallowed ability }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { expect_allowed ability }
      end
    end
  end
end

RSpec.shared_examples 'runner policy' do |ability, scope: %i[instance_runner group_runner project_runner]|
  context 'without access' do
    let_it_be(:user) { create(:user) }

    it_behaves_like 'does not allow accessing runners/runner managers on any scope', ability
  end

  context 'with guest access' do
    let(:user) { guest }

    it_behaves_like 'does not allow accessing runners/runner managers on any scope', ability
  end

  context 'with reporter access' do
    let(:user) { reporter }

    it_behaves_like 'does not allow accessing runners/runner managers on any scope', ability
  end

  context 'with developer access' do
    let(:user) { developer }

    it_behaves_like 'does not allow accessing runners/runner managers on any scope', ability
  end

  context 'with maintainer access' do
    let(:user) { maintainer }

    if scope.include?(:instance_runner)
      context 'with instance runner' do
        let(:runner) { instance_runner }

        it { expect_allowed ability }
      end
    end

    if scope.include?(:group_runner)
      it_behaves_like 'a policy allowing accessing group runner/runner manager depending on runner sharing',
        ability, :maintainer
    end

    it_behaves_like 'runner policy with project runner', ability if scope.include?(:project_runner)
  end

  it_behaves_like 'runner policy for user with owner access', ability, scope: scope
  it_behaves_like 'runner policy for admin user', ability, scope: scope
end
