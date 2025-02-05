# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runner, type: :model, factory_default: :keep, feature_category: :runner do
  include StubGitlabCalls

  let_it_be(:organization, freeze: true) { create_default(:organization) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:other_project) { create(:project, group: group) }

  describe 'associations' do
    it { is_expected.to belong_to(:creator).class_name('User').optional }

    it { is_expected.to have_many(:runner_managers).inverse_of(:runner) }
    it { is_expected.to have_many(:builds) }
    it { is_expected.to have_one(:last_build).class_name('Ci::Build') }
    it { is_expected.to have_many(:running_builds).inverse_of(:runner) }

    it { is_expected.to have_many(:runner_projects).inverse_of(:runner) }
    it { is_expected.to have_many(:projects).through(:runner_projects) }

    it { is_expected.to have_many(:runner_namespaces).inverse_of(:runner) }
    it { is_expected.to have_many(:groups).through(:runner_namespaces) }
    it { is_expected.to have_one(:owner_runner_namespace).class_name('Ci::RunnerNamespace') }

    it { is_expected.to have_many(:taggings).class_name('Ci::RunnerTagging').inverse_of(:runner) }
    it { is_expected.to have_many(:tags).class_name('Ci::Tag') }
  end

  it_behaves_like 'having unique enum values'

  it_behaves_like 'it has loose foreign keys' do
    let(:factory_name) { :ci_runner }
  end

  context 'loose foreign key on ci_runners.creator_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:user) }
      let!(:model) { create(:ci_runner, creator: parent) }
    end
  end

  describe 'groups association' do
    # Due to other associations such as projects this whole spec is allowed to
    # generate cross-database queries. So we have this temporary spec to
    # validate that at least groups association does not generate cross-DB
    # queries.
    it 'does not create a cross-database query' do
      runner = create(:ci_runner, :group, groups: [group])

      with_cross_joins_prevented do
        expect(runner.groups.count).to eq(1)
      end
    end
  end

  describe '#owner_runner_namespace' do
    it 'considers the first group' do
      runner = create(:ci_runner, :group, groups: [group])

      with_cross_joins_prevented do
        expect(runner.owner_runner_namespace.namespace_id).to eq(runner.groups.first.id)
      end
    end
  end

  describe 'projects association' do
    let(:runner) { create(:ci_runner, :project, projects: [project]) }

    it 'does not create a cross-database query' do
      with_cross_joins_prevented do
        expect(runner.projects.count).to eq(1)
      end
    end
  end

  describe 'acts_as_taggable' do
    let(:tag_name) { 'tag123' }

    context 'on save' do
      let(:runner) { create(:ci_runner, :group, groups: [group]) }

      before do
        runner.tag_list = [tag_name]
      end

      context 'tag does not exist' do
        let(:tag_name) { 'new-tag' }

        it 'creates a tag' do
          expect { runner.save! }.to change(Ci::Tag, :count).by(1)
        end

        it 'creates an association to the tag' do
          runner.save!

          expect(described_class.tagged_with(tag_name)).to include(runner)
        end
      end

      context 'tag already exists' do
        before do
          Ci::Tag.create!(name: tag_name)
        end

        it 'does not create a tag' do
          expect { runner.save! }.not_to change(Ci::Tag, :count)
        end

        it 'creates an association to the tag' do
          runner.save!

          expect(described_class.tagged_with(tag_name)).to include(runner)
        end
      end
    end
  end

  describe 'validation' do
    it { is_expected.to validate_length_of(:name).is_at_most(256) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
    it { is_expected.to validate_presence_of(:access_level) }
    it { is_expected.to validate_presence_of(:runner_type) }
    it { is_expected.to validate_presence_of(:registration_type) }
    it { is_expected.to validate_presence_of(:sharding_key_id) }

    context 'when runner is instance type' do
      let(:runner) { build(:ci_runner, :instance_type) }

      it { expect(runner).to be_valid }

      context 'when sharding_key_id is present' do
        let(:runner) { build(:ci_runner, :instance_type, sharding_key_id: non_existing_record_id) }

        it 'is invalid' do
          expect(runner).to be_invalid
          expect(runner.errors.full_messages).to contain_exactly('Runner cannot have sharding_key_id assigned')
        end
      end
    end

    context 'when runner is not allowed to pick untagged jobs' do
      context 'when runner does not have tags' do
        let(:runner) { build(:ci_runner, tag_list: [], run_untagged: false) }

        it { expect(runner).to be_invalid }
      end

      context 'when runner has too many tags' do
        let(:runner) { build(:ci_runner, tag_list: (1..::Ci::Runner::TAG_LIST_MAX_LENGTH + 1).map { |i| "tag#{i}" }, run_untagged: false) }

        it { expect(runner).to be_invalid }
      end

      context 'when runner has tags' do
        let(:runner) { build(:ci_runner, tag_list: ['tag'], run_untagged: false) }

        it { expect(runner).to be_valid }
      end
    end

    describe '#exactly_one_group' do
      let(:runner) { create(:ci_runner, :group, groups: [group]) }

      it 'disallows assigning group if already assigned to a group' do
        runner.runner_namespaces << create(:ci_runner_namespace, runner: runner)

        expect(runner).not_to be_valid
        expect(runner.errors.full_messages).to include('Runner needs to be assigned to exactly one group')
      end
    end

    context 'runner_type validations' do
      it 'disallows assigning group to project_type runner' do
        project_runner = build(:ci_runner, :project, :without_projects, groups: [group])

        expect(project_runner).not_to be_valid
        expect(project_runner.errors.full_messages).to include('Runner cannot have groups assigned')
      end

      it 'disallows assigning group to instance_type runner' do
        instance_runner = build(:ci_runner, :instance, groups: [group])

        expect(instance_runner).not_to be_valid
        expect(instance_runner.errors.full_messages).to include('Runner cannot have groups assigned')
      end

      it 'disallows assigning project to group_type runner' do
        group_runner = build(:ci_runner, :instance, projects: [project])

        expect(group_runner).not_to be_valid
        expect(group_runner.errors.full_messages).to include('Runner cannot have projects assigned')
      end

      it 'disallows assigning project to instance_type runner' do
        instance_runner = build(:ci_runner, :instance, projects: [project])

        expect(instance_runner).not_to be_valid
        expect(instance_runner.errors.full_messages).to include('Runner cannot have projects assigned')
      end

      it 'fails to save a group assigned to a project runner even if the runner is already saved' do
        project_runner = create(:ci_runner, :project, projects: [project])

        expect { create(:group, runners: [project_runner]) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'cost factors validations' do
      it 'disallows :private_projects_minutes_cost_factor being nil' do
        runner = build(:ci_runner, private_projects_minutes_cost_factor: nil)

        expect(runner).to be_invalid
        expect(runner.errors.full_messages).to include('Private projects minutes cost factor needs to be non-negative')
      end

      it 'disallows :public_projects_minutes_cost_factor being nil' do
        runner = build(:ci_runner, public_projects_minutes_cost_factor: nil)

        expect(runner).to be_invalid
        expect(runner.errors.full_messages).to include('Public projects minutes cost factor needs to be non-negative')
      end

      it 'disallows :private_projects_minutes_cost_factor being negative' do
        runner = build(:ci_runner, private_projects_minutes_cost_factor: -1.1)

        expect(runner).to be_invalid
        expect(runner.errors.full_messages).to include('Private projects minutes cost factor needs to be non-negative')
      end

      it 'disallows :public_projects_minutes_cost_factor being negative' do
        runner = build(:ci_runner, public_projects_minutes_cost_factor: -2.2)

        expect(runner).to be_invalid
        expect(runner.errors.full_messages).to include('Public projects minutes cost factor needs to be non-negative')
      end
    end

    describe '#no_allowed_plan_ids' do
      let_it_be(:default_plan) { create(:default_plan) }

      context 'when runner is instance type' do
        let(:runner) { create(:ci_runner, :instance) }

        it 'allows assign allowed_plans' do
          runner.allowed_plan_ids = [default_plan.id]

          expect(runner).to be_valid
          puts runner.errors.full_messages
        end
      end

      context 'when runner is not an instance type' do
        let(:runner) { create(:ci_runner, :group, groups: [group]) }

        subject { runner.allowed_plan_ids = [default_plan.id] }

        it 'allows assign allowed_plans' do
          runner.allowed_plan_ids = [default_plan.id]

          expect(runner).not_to be_valid
          expect(runner.errors.full_messages).to include('Runner cannot have allowed plans assigned')
          puts runner.errors.full_messages
        end
      end
    end
  end

  describe 'constraints' do
    it '.UPDATE_CONTACT_COLUMN_EVERY' do
      expect(described_class::UPDATE_CONTACT_COLUMN_EVERY.max)
        .to be <= described_class::ONLINE_CONTACT_TIMEOUT
    end
  end

  describe '#access_level' do
    context 'when creating new runner and access_level is nil' do
      let(:runner) { build(:ci_runner, access_level: nil) }

      it "object is invalid" do
        expect(runner).not_to be_valid
      end
    end

    context 'when creating new runner and access_level is defined in enum' do
      let(:runner) { build(:ci_runner, access_level: :not_protected) }

      it "object is valid" do
        expect(runner).to be_valid
      end
    end

    context 'when creating new runner and access_level is not defined in enum' do
      it "raises an error" do
        expect { build(:ci_runner, access_level: :this_is_not_defined) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#owner' do
    subject(:owner) { runner.owner }

    context 'when runner does not have creator_id' do
      let_it_be(:runner) { create(:ci_runner, :instance) }

      it { is_expected.to be_nil }
    end

    context 'when runner has creator' do
      let_it_be(:creator) { create(:user) }
      let_it_be(:runner) { create(:ci_runner, creator: creator) }

      it { is_expected.to eq creator }
    end
  end

  describe '.instance_type' do
    let!(:group_runner) { create(:ci_runner, :group, groups: [group]) }
    let!(:project_runner) { create(:ci_runner, :project, projects: [project]) }
    let!(:shared_runner) { create(:ci_runner, :instance) }

    it 'returns only shared runners' do
      expect(described_class.instance_type).to contain_exactly(shared_runner)
    end
  end

  describe '.belonging_to_project' do
    it 'returns the project runner' do
      # own
      own_project = create(:project)
      own_runner = create(:ci_runner, :project, projects: [own_project])

      # other
      create(:ci_runner, :project, projects: [other_project])

      expect(described_class.belonging_to_project(own_project.id)).to eq [own_runner]
    end
  end

  shared_examples '.belonging_to_parent_groups_of_project' do
    let_it_be(:group1) { create(:group) }
    let_it_be(:project1) { create(:project, group: group1) }
    let_it_be(:runner1) { create(:ci_runner, :group, groups: [group1]) }

    let_it_be(:group2) { create(:group) }
    let_it_be(:project2) { create(:project, group: group2) }
    let_it_be(:runner2) { create(:ci_runner, :group, groups: [group2]) }

    let(:project_id) { project1.id }

    subject(:result) { described_class.belonging_to_parent_groups_of_project(project_id) }

    it 'returns the group runner' do
      expect(result).to contain_exactly(runner1)
    end

    context 'with a parent group with a runner', :sidekiq_inline do
      before do
        group1.update!(parent: group2)
      end

      it 'returns the group runner from the group and the parent group' do
        expect(result).to contain_exactly(runner1, runner2)
      end
    end

    context 'with multiple project ids' do
      let(:project_id) { [project1.id, project2.id] }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError)
      end
    end
  end

  it_behaves_like '.belonging_to_parent_groups_of_project'

  context 'with instance runners sharing enabled' do
    # group specific
    let_it_be(:group) { create(:group, shared_runners_enabled: true) }
    let_it_be(:project) { create(:project, group: group, shared_runners_enabled: true) }
    let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }

    # project specific
    let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }

    # globally shared
    let_it_be(:shared_runner) { create(:ci_runner, :instance) }

    describe '.owned_or_instance_wide' do
      subject { described_class.owned_or_instance_wide(project.id) }

      it 'returns a shared, project and group runner' do
        is_expected.to contain_exactly(group_runner, project_runner, shared_runner)
      end
    end

    describe '.group_or_instance_wide' do
      subject { described_class.group_or_instance_wide(group) }

      before do
        # Ensure the project runner is instantiated
        project_runner
      end

      it 'returns a globally shared and a group runner' do
        is_expected.to contain_exactly(group_runner, shared_runner)
      end
    end
  end

  context 'with instance runners sharing disabled' do
    # group specific
    let_it_be(:group) { create(:group, shared_runners_enabled: false) }
    let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }

    let(:group_runners_enabled) { true }
    let(:project) { create(:project, group: group, shared_runners_enabled: false) }

    # project specific
    let(:project_runner) { create(:ci_runner, :project, projects: [project]) }

    # globally shared
    let_it_be(:shared_runner) { create(:ci_runner, :instance) }

    before do
      project.update!(group_runners_enabled: group_runners_enabled)
    end

    describe '.owned_or_instance_wide' do
      subject { described_class.owned_or_instance_wide(project.id) }

      context 'with group runners disabled' do
        let(:group_runners_enabled) { false }

        it 'returns only the project runner' do
          is_expected.to contain_exactly(project_runner)
        end
      end

      context 'with group runners enabled' do
        let(:group_runners_enabled) { true }

        it 'returns a project runner and a group runner' do
          is_expected.to contain_exactly(group_runner, project_runner)
        end
      end
    end

    describe '.group_or_instance_wide' do
      subject { described_class.group_or_instance_wide(group) }

      before do
        # Ensure the project runner is instantiated
        project_runner
      end

      it 'returns a group runner' do
        is_expected.to contain_exactly(group_runner)
      end
    end
  end

  describe '#display_name' do
    let(:args) { {} }
    let(:runner) { build(:ci_runner, **args) }

    subject(:display_name) { runner.display_name }

    it 'returns the default description' do
      is_expected.to eq runner.description
    end

    context 'when description has a value' do
      let(:args) { { description: 'Linux/Ruby-1.9.3-p448' } }

      it 'returns the specified description' do
        is_expected.to eq args[:description]
      end
    end

    context 'when description is empty and token have a value' do
      let(:args) { { description: '', token: 'token' } }

      it 'returns the short_sha' do
        is_expected.to eq runner.short_sha
      end
    end
  end

  describe '#only_for' do
    let_it_be_with_reload(:runner) { create(:ci_runner, :project, projects: [project]) }

    subject { runner.only_for?(project) }

    context 'with matching project' do
      it { is_expected.to be_truthy }
    end

    context 'without matching project' do
      let_it_be(:project) { create(:project) }

      it { is_expected.to be_falsey }
    end

    context 'with runner having multiple projects' do
      let_it_be(:runner_project) { create(:ci_runner_project, project: other_project, runner: runner) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#assign_to' do
    subject(:assign_to) { runner.assign_to(project) }

    context 'with instance runner' do
      let(:runner) { create(:ci_runner, :instance) }

      it 'raises an error' do
        expect { assign_to }
          .to raise_error(ArgumentError, 'Transitioning an instance runner to a project runner is not supported')
      end
    end

    context 'with group runner' do
      let(:runner) { create(:ci_runner, :group, groups: [group]) }

      it 'raises an error' do
        expect { assign_to }
          .to raise_error(ArgumentError, 'Transitioning a group runner to a project runner is not supported')
      end
    end

    context 'with project runner' do
      let_it_be_with_refind(:owner_project) { create(:project, group: group) }
      let_it_be_with_reload(:fallback_owner_project) { create(:project, group: group) }

      let(:associated_projects) { [owner_project, fallback_owner_project] }
      let(:runner) { create(:ci_runner, :project, projects: associated_projects) }

      it 'assigns runner to project' do
        expect(assign_to).to be_truthy

        expect(runner).to be_project_type
        expect(runner.runner_projects.pluck(:project_id))
          .to contain_exactly(project.id, owner_project.id, fallback_owner_project.id)
      end

      it 'does not change sharding_key_id or owner' do
        expect { assign_to }
          .to not_change { runner.sharding_key_id }.from(owner_project.id)
          .and not_change { runner.owner }.from(owner_project)
      end

      context 'when sharding_key_id does not point to an existing project' do
        subject(:assign_to) do
          owner_project.destroy!

          runner.assign_to(project)
        end

        it 'changes sharding_key_id and owner to fallback owner project' do
          expect { assign_to }
            .to change { runner.sharding_key_id }.from(owner_project.id).to(fallback_owner_project.id)
            .and change { runner.owner }.from(owner_project).to(fallback_owner_project)
        end

        context 'and fallback does not exist' do
          let(:associated_projects) { [owner_project] }

          it 'changes sharding_key_id and owner to newly-assigned project' do
            expect { assign_to }
              .to change { runner.sharding_key_id }.from(owner_project.id).to(project.id)
              .and change { runner.owner }.from(owner_project).to(project)
          end
        end
      end
    end
  end

  describe '.recent', :freeze_time do
    subject { described_class.recent }

    let!(:runner1) { create(:ci_runner, :unregistered, :created_within_stale_deadline) }
    let!(:runner2) { create(:ci_runner, :unregistered, :stale) }
    let!(:runner3) { create(:ci_runner, :created_within_stale_deadline, :contacted_within_stale_deadline) }
    let!(:runner4) { create(:ci_runner, :stale, :contacted_within_stale_deadline) }
    let!(:runner5) { create(:ci_runner, :stale) }

    it { is_expected.to contain_exactly(runner1, runner3, runner4) }
  end

  describe '.active' do
    subject { described_class.active(active_value) }

    let_it_be(:runner1) { create(:ci_runner, :instance, :paused) }
    let_it_be(:runner2) { create(:ci_runner, :instance) }

    context 'with active_value set to false' do
      let(:active_value) { false }

      it 'returns paused runners' do
        is_expected.to contain_exactly(runner1)
      end
    end

    context 'with active_value set to true' do
      let(:active_value) { true }

      it 'returns active runners' do
        is_expected.to contain_exactly(runner2)
      end
    end
  end

  describe '.paused' do
    subject(:paused) { described_class.paused }

    let!(:runner1) { create(:ci_runner, :instance, :paused) }
    let!(:runner2) { create(:ci_runner, :instance) }

    it 'returns paused runners' do
      expect(described_class).to receive(:active).with(false).and_call_original

      expect(paused).to contain_exactly(runner1)
    end
  end

  describe '.with_creator_id' do
    let_it_be(:admin) { create(:admin) }
    let_it_be(:user2) { create(:user) }

    let_it_be(:user_runner1) { create(:ci_runner, creator: user2) }
    let_it_be(:admin_runner1) { create(:ci_runner, creator: admin) }
    let_it_be(:admin_runner2) { create(:ci_runner, creator: admin) }
    let_it_be(:runner_without_creator) { create(:ci_runner, creator: nil) }

    subject { described_class.with_creator_id(admin.id.to_s) }

    it { is_expected.to contain_exactly(admin_runner1, admin_runner2) }
  end

  describe '.created_by_admins' do
    let_it_be(:admin) { create(:admin) }
    let_it_be(:user2) { create(:user) }
    let_it_be(:admin_runner) { create(:ci_runner, creator: admin) }
    let_it_be(:other_runner) { create(:ci_runner, creator: user2) }
    let_it_be(:project_runner) { create(:ci_runner, :project, :without_projects, creator: admin) }

    subject { described_class.created_by_admins }

    it { is_expected.to contain_exactly(admin_runner, project_runner) }
  end

  describe '.with_version_prefix' do
    subject { described_class.with_version_prefix('15.11.') }

    let_it_be(:runner1) { create(:ci_runner) }
    let_it_be(:runner2) { create(:ci_runner) }
    let_it_be(:runner3) { create(:ci_runner) }

    before_all do
      create(:ci_runner_machine, runner: runner1, version: '15.11.0')
      create(:ci_runner_machine, runner: runner2, version: '15.9.0')
      create(:ci_runner_machine, runner: runner3, version: '15.9.0')
      # Add another runner_machine to runner3 to ensure edge case is handled (searching multiple machines in a single runner)
      create(:ci_runner_machine, runner: runner3, version: '15.11.5')
    end

    it 'returns runners containing runner managers with versions starting with 15.11.' do
      is_expected.to contain_exactly(runner1, runner3)
    end
  end

  describe '#stale?', :clean_gitlab_redis_cache, :freeze_time do
    let(:runner) { build(:ci_runner, :instance) }

    subject { runner.stale? }

    before do
      allow(Ci::Runners::ProcessRunnerVersionUpdateWorker).to receive(:perform_async).once
    end

    context 'table tests' do
      using RSpec::Parameterized::TableSyntax

      let(:stale_deadline) { described_class.stale_deadline }
      let(:almost_stale_deadline) { 1.second.after(stale_deadline) }

      where(:created_at, :contacted_at, :expected_stale?) do
        nil                         | nil                         | false
        ref(:stale_deadline)        | ref(:stale_deadline)        | true
        ref(:stale_deadline)        | ref(:almost_stale_deadline) | false
        ref(:stale_deadline)        | nil                         | true
        ref(:almost_stale_deadline) | nil                         | false
      end

      with_them do
        before do
          runner.created_at = created_at
          runner.contacted_at = contacted_at
        end

        it { is_expected.to eq(expected_stale?) }

        context 'with cache value' do
          before do
            stub_redis_runner_contacted_at(contacted_at.to_s)
          end

          it { is_expected.to eq(expected_stale?) }
        end

        def stub_redis_runner_contacted_at(value)
          return unless created_at

          Gitlab::Redis::Cache.with do |redis|
            cache_key = runner.send(:cache_attribute_key)
            expect(redis).to receive(:get).with(cache_key)
              .and_return({ contacted_at: value }.to_json).at_least(:once)
          end
        end
      end
    end
  end

  describe '#online?', :clean_gitlab_redis_cache, :freeze_time do
    subject { runner.online? }

    context 'never contacted' do
      let(:runner) { build(:ci_runner, :unregistered) }

      it { is_expected.to be_falsey }
    end

    context 'contacted long time ago' do
      let(:runner) { build(:ci_runner, :stale) }

      it { is_expected.to be_falsey }
    end

    context 'almost offline' do
      let(:runner) { build(:ci_runner, :almost_offline) }

      it { is_expected.to be_truthy }
    end

    context 'with cache value' do
      let(:runner) { create(:ci_runner, :stale) }

      before do
        stub_redis_runner_contacted_at(cached_contacted_at.to_s)
      end

      context 'contacted long time ago' do
        let(:cached_contacted_at) { runner.uncached_contacted_at }

        it { is_expected.to be_falsey }
      end

      context 'contacted 1s ago' do
        let(:cached_contacted_at) { 1.second.ago }

        it { is_expected.to be_truthy }
      end

      def stub_redis_runner_contacted_at(value)
        Gitlab::Redis::Cache.with do |redis|
          cache_key = runner.send(:cache_attribute_key)
          expect(redis).to receive(:get).with(cache_key)
            .and_return({ contacted_at: value }.to_json).at_least(:once)
        end
      end
    end
  end

  describe '.with_executing_builds' do
    subject(:scope) { described_class.with_executing_builds }

    let_it_be(:runners_by_status) do
      Ci::HasStatus::AVAILABLE_STATUSES.index_with { |_status| create(:ci_runner) }
    end

    let_it_be(:busy_runners) do
      Ci::HasStatus::EXECUTING_STATUSES.map { |status| runners_by_status[status] }
    end

    context 'with no builds running' do
      it { is_expected.to be_empty }
    end

    context 'with builds' do
      before_all do
        pipeline = create(:ci_pipeline, :running)

        Ci::HasStatus::AVAILABLE_STATUSES.each do |status|
          create(:ci_build, status, runner: runners_by_status[status], pipeline: pipeline)
        end
      end

      it { is_expected.to match_array(busy_runners) }
    end
  end

  describe '#matches_build?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:pipeline) { create(:ci_pipeline) }
    let_it_be_with_refind(:build) { create(:ci_build, pipeline: pipeline) }
    let_it_be(:runner_project) { build.project }
    let_it_be_with_refind(:runner) { create(:ci_runner, :project, projects: [runner_project]) }

    let(:tag_list) { [] }
    let(:run_untagged) { true }

    before do
      runner.tag_list = tag_list
      runner.run_untagged = run_untagged
    end

    subject { runner.matches_build?(build) }

    context 'when runner does not have tags' do
      it { is_expected.to be_truthy }

      it 'cannot handle build with tags' do
        build.tag_list = ['aa']

        is_expected.to be_falsey
      end
    end

    context 'when runner has tags' do
      let(:tag_list) { %w[bb cc] }

      shared_examples 'tagged build picker' do
        it 'can handle build with matching tags' do
          build.tag_list = ['bb']

          is_expected.to be_truthy
        end

        it 'cannot handle build without matching tags' do
          build.tag_list = ['aa']

          is_expected.to be_falsey
        end
      end

      context 'when runner can pick untagged jobs' do
        it { is_expected.to be_truthy }

        it_behaves_like 'tagged build picker'
      end

      context 'when runner cannot pick untagged jobs' do
        let(:run_untagged) { false }

        it { is_expected.to be_falsey }

        it_behaves_like 'tagged build picker'
      end
    end

    context 'when runner is shared' do
      let(:runner) { create(:ci_runner, :instance) }

      it { is_expected.to be_truthy }

      context 'when runner is locked' do
        let(:runner) { create(:ci_runner, :instance, locked: true) }

        it { is_expected.to be_truthy }
      end

      it 'does not query for owned or instance runners' do
        expect(described_class).not_to receive(:owned_or_instance_wide)

        subject
      end
    end

    context 'when runner is not shared' do
      context 'when runner is assigned to a project' do
        it { is_expected.to be_truthy }
      end

      context 'when runner is assigned to a group' do
        let(:group) { create(:group, projects: [build.project]) }
        let(:runner) { create(:ci_runner, :group, tag_list: tag_list, run_untagged: run_untagged, groups: [group]) }

        it { is_expected.to be_truthy }

        it 'knows namespace id it is assigned to' do
          expect(runner.namespace_ids).to eq [group.id]
        end
      end
    end

    context 'when access_level of runner is not_protected' do
      before do
        runner.not_protected!
      end

      context 'when build is protected' do
        before do
          build.protected = true
        end

        it { is_expected.to be_truthy }
      end

      context 'when build is unprotected' do
        before do
          build.protected = false
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'when access_level of runner is ref_protected' do
      before do
        runner.ref_protected!
      end

      context 'when build is protected' do
        before do
          build.protected = true
        end

        it { is_expected.to be_truthy }
      end

      context 'when build is unprotected' do
        before do
          build.protected = false
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'matches tags' do
      where(:run_untagged, :runner_tags, :build_tags, :result) do
        true  | []      | []      | true
        true  | []      | ['a']   | false
        true  | %w[a b] | ['a']   | true
        true  | ['a']   | %w[a b] | false
        true  | ['a']   | ['a']   | true
        false | ['a']   | ['a']   | true
        false | ['b']   | ['a']   | false
        false | %w[a b] | ['a']   | true
      end

      with_them do
        let(:tag_list) { runner_tags }

        before do
          build.tag_list = build_tags
        end

        it { is_expected.to eq(result) }
      end
    end
  end

  describe '#status', :freeze_time do
    let(:runner) { build(:ci_runner, *Array.wrap(traits)) }

    subject { runner.status }

    context 'stale, never contacted' do
      let(:traits) { %i[unregistered stale] }

      it { is_expected.to eq(:stale) }

      context 'created recently, never contacted' do
        let(:traits) { %i[unregistered online] }

        it { is_expected.to eq(:never_contacted) }
      end
    end

    context 'online, paused' do
      let(:traits) { %i[paused online] }

      it { is_expected.to eq(:online) }
    end

    context 'online' do
      let(:traits) { :almost_offline }

      it { is_expected.to eq(:online) }
    end

    context 'offline' do
      let(:traits) { :offline }

      it { is_expected.to eq(:offline) }
    end

    context 'stale' do
      let(:traits) { :stale }

      it { is_expected.to eq(:stale) }
    end
  end

  describe '#deprecated_rest_status', :freeze_time do
    let(:runner) { build(:ci_runner, *Array.wrap(traits)) }

    subject { runner.deprecated_rest_status }

    context 'never connected' do
      let(:traits) { :unregistered }

      it { is_expected.to eq(:never_contacted) }
    end

    context 'contacted recently' do
      let(:traits) { :almost_offline }

      it { is_expected.to eq(:online) }
    end

    context 'contacted long time ago' do
      let(:traits) { :stale }

      it { is_expected.to eq(:stale) }
    end

    context 'paused' do
      let(:traits) { %i[paused online] }

      it { is_expected.to eq(:paused) }
    end
  end

  describe '#tick_runner_queue' do
    let(:runner) { build(:ci_runner) }

    it 'returns a new last_update value' do
      expect(runner.tick_runner_queue).not_to be_empty
    end

    it 'sticks the runner to the primary and calls the original method' do
      runner = create(:ci_runner)

      expect(described_class.sticking).to receive(:stick).with(:runner, runner.id)

      expect(Gitlab::Workhorse).to receive(:set_key_and_notify)

      runner.tick_runner_queue
    end
  end

  describe '#ensure_runner_queue_value' do
    let(:runner) { create(:ci_runner) }

    it 'sets a new last_update value when it is called the first time' do
      last_update = runner.ensure_runner_queue_value

      expect(value_in_queues).to eq(last_update)
    end

    it 'does not change if it is not expired and called again' do
      last_update = runner.ensure_runner_queue_value

      expect(runner.ensure_runner_queue_value).to eq(last_update)
      expect(value_in_queues).to eq(last_update)
    end

    context 'updates runner queue after changing editable value' do
      let!(:last_update) { runner.ensure_runner_queue_value }

      before do
        Ci::Runners::UpdateRunnerService.new(nil, runner).execute(description: 'new runner')
      end

      it 'sets a new last_update value' do
        expect(value_in_queues).not_to eq(last_update)
      end
    end

    context 'does not update runner value after save' do
      let!(:last_update) { runner.ensure_runner_queue_value }

      before do
        runner.touch
      end

      it 'has an old last_update value' do
        expect(value_in_queues).to eq(last_update)
      end
    end

    def value_in_queues
      Gitlab::Redis::Workhorse.with do |redis|
        runner_queue_key = runner.send(:runner_queue_key)
        redis.get(runner_queue_key)
      end
    end
  end

  describe '#heartbeat', :freeze_time do
    subject(:heartbeat) do
      runner.heartbeat
    end

    context 'when database was updated recently' do
      let(:runner) { create(:ci_runner, :almost_offline) }

      it 'updates cache' do
        expect_redis_update

        heartbeat
      end
    end

    context 'when database was not updated recently' do
      context 'with invalid runner' do
        let(:runner) { create(:ci_runner, :offline, :project, :without_projects) }

        it 'still updates contacted at in redis cache and database' do
          expect(runner).to be_invalid

          expect_redis_update(contacted_at: Time.current, creation_state: :finished)
          expect { heartbeat }.to change { runner.reload.read_attribute(:contacted_at) }
        end

        it 'only updates contacted at in redis cache and database' do
          expect_redis_update(contacted_at: Time.current, creation_state: :finished)
          expect { heartbeat }.to change { runner.reload.read_attribute(:contacted_at) }
        end
      end
    end

    def expect_redis_update(values = anything)
      values_json = values == anything ? anything : Gitlab::Json.dump(values)

      Gitlab::Redis::Cache.with do |redis|
        redis_key = runner.send(:cache_attribute_key)
        expect(redis).to receive(:set).with(redis_key, values_json, any_args).and_call_original
      end
    end

    def does_db_update
      expect { heartbeat }.to change { runner.reload.read_attribute(:contacted_at) }
    end
  end

  describe '#clear_heartbeat', :freeze_time do
    let!(:runner) { create(:ci_runner) }

    it 'clears contacted at' do
      expect do
        runner.heartbeat
      end.to change { runner.reload.contacted_at }.from(nil).to(Time.current)
        .and change { runner.reload.uncached_contacted_at }.from(nil).to(Time.current)

      expect do
        runner.clear_heartbeat
      end.to change { runner.reload.contacted_at }.from(Time.current).to(nil)
        .and change { runner.reload.uncached_contacted_at }.from(Time.current).to(nil)
    end
  end

  describe '#destroy' do
    let(:runner) { create(:ci_runner) }

    context 'when there is a tick in the queue' do
      let!(:queue_key) { runner.send(:runner_queue_key) }

      before do
        runner.tick_runner_queue
      end

      it 'cleans up the queue' do
        expect(Gitlab::Workhorse).to receive(:cleanup_key).with(queue_key)

        runner.destroy!
      end
    end
  end

  describe '.assignable_for' do
    let_it_be(:project) { create(:project) }
    let_it_be(:group) { create(:group) }
    let_it_be(:another_project) { create(:project) }
    let_it_be(:unlocked_project_runner) { create(:ci_runner, :project, projects: [project]) }
    let_it_be(:locked_project_runner) { create(:ci_runner, :project, locked: true, projects: [project]) }
    let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }
    let_it_be(:instance_runner) { create(:ci_runner, :instance) }

    context 'with already assigned project' do
      subject { described_class.assignable_for(project) }

      it { is_expected.to be_empty }
    end

    context 'with a different project' do
      subject { described_class.assignable_for(another_project) }

      it { is_expected.to include(unlocked_project_runner) }
      it { is_expected.not_to include(group_runner) }
      it { is_expected.not_to include(locked_project_runner) }
      it { is_expected.not_to include(instance_runner) }
    end
  end

  describe 'Project-related queries' do
    let_it_be(:projects) { create_list(:project, 2, group: group) }

    describe '#owner' do
      let(:project_runner) { create(:ci_runner, :project, projects: associated_projects) }

      subject(:owner) { project_runner.owner }

      context 'with project1 as first project associated with runner' do
        let(:associated_projects) { projects }

        it { is_expected.to eq projects.first }
      end

      context 'with project2 as first project associated with runner' do
        let(:associated_projects) { projects.reverse }

        it { is_expected.to eq projects.last }
      end

      context 'when owner project is to be deleted' do
        let_it_be_with_refind(:owner_project) { create(:project, group: group) }

        let(:associated_projects) { [owner_project, other_project, projects.last] }

        specify 'projects are associated in the expected order' do
          expect(
            project_runner.runner_projects.order(id: :asc).pluck(:project_id)
          ).to eq associated_projects.map(&:id)
        end

        it { is_expected.to eq owner_project }

        context 'and owner project is deleted' do
          before do
            owner_project.destroy!
          end

          it { is_expected.to eq other_project }
          it { is_expected.not_to eq projects.last }

          context 'and projects are associated in different order' do
            let(:associated_projects) { [owner_project, projects.last, other_project] }

            it 'is not sensitive to project ID order' do
              is_expected.to eq projects.last
            end
          end
        end
      end
    end

    describe '#belongs_to_one_project?' do
      it "returns false if there are two projects runner is assigned to" do
        runner = create(:ci_runner, :project, projects: projects)

        expect(runner.belongs_to_one_project?).to be_falsey
      end

      it 'returns true if there is only one project runner is assigned to' do
        runner = create(:ci_runner, :project, projects: projects.take(1))

        expect(runner.belongs_to_one_project?).to be_truthy
      end
    end

    describe '#belongs_to_more_than_one_project?' do
      context 'project runner' do
        context 'two projects assigned to runner' do
          let(:runner) { create(:ci_runner, :project, projects: projects) }

          it 'returns true' do
            expect(runner.belongs_to_more_than_one_project?).to be_truthy
          end
        end

        context 'one project assigned to runner' do
          let(:runner) { create(:ci_runner, :project, projects: projects.take(1)) }

          it 'returns false' do
            expect(runner.belongs_to_more_than_one_project?).to be_falsey
          end
        end
      end

      context 'group runner' do
        let(:runner) { create(:ci_runner, :group, groups: [group]) }

        it 'returns false' do
          expect(runner.belongs_to_more_than_one_project?).to be_falsey
        end
      end

      context 'shared runner' do
        let(:runner) { create(:ci_runner, :instance) }

        it 'returns false' do
          expect(runner.belongs_to_more_than_one_project?).to be_falsey
        end
      end
    end
  end

  describe '#save_tags' do
    let(:runner) { build(:ci_runner, tag_list: ['tag']) }

    it 'saves tags' do
      runner.save!

      expect(runner.tags.count).to eq(1)
      expect(runner.tags.first.name).to eq('tag')
      expect(runner.taggings.count).to eq(1)
    end

    it 'strips tags' do
      runner.tag_list = ['       taga', 'tagb      ', '   tagc    ']

      runner.save!
      expect(runner.tags.map(&:name)).to match_array(%w[taga tagb tagc])
    end

    context 'with BulkInsertableTags.with_bulk_insert_tags' do
      it 'does not save_tags' do
        Ci::BulkInsertableTags.with_bulk_insert_tags do
          runner.save!
        end

        expect(runner.tags).to be_empty
      end

      context 'over TAG_LIST_MAX_LENGTH' do
        let(:tag_list) { (1..described_class::TAG_LIST_MAX_LENGTH + 1).map { |i| "tag#{i}" } }
        let(:runner) { build(:ci_runner, tag_list: tag_list) }

        it 'fails validation if over tag limit' do
          Ci::BulkInsertableTags.with_bulk_insert_tags do
            expect { runner.save! }.to raise_error(ActiveRecord::RecordInvalid)
          end

          expect(runner.tags).to be_empty
        end
      end
    end
  end

  describe '#has_tags?' do
    context 'when runner has tags' do
      subject { build(:ci_runner, tag_list: ['tag']) }

      it { is_expected.to have_tags }
    end

    context 'when runner does not have tags' do
      subject { build(:ci_runner, tag_list: []) }

      it { is_expected.not_to have_tags }
    end
  end

  describe '.search' do
    let_it_be(:runner) { create(:ci_runner, token: '123abc', description: 'test runner') }

    it 'returns runners with a matching token' do
      expect(described_class.search(runner.token)).to eq([runner])
    end

    it 'does not return runners with a partially matching token' do
      expect(described_class.search(runner.token[0..2])).to be_empty
    end

    it 'does not return runners with a matching token with different casing' do
      expect(described_class.search(runner.token.upcase)).to be_empty
    end

    it 'returns runners with a matching description' do
      expect(described_class.search(runner.description)).to eq([runner])
    end

    it 'returns runners with a partially matching description' do
      expect(described_class.search(runner.description[0..2])).to eq([runner])
    end

    it 'returns runners with a matching description regardless of the casing' do
      expect(described_class.search(runner.description.upcase)).to eq([runner])
    end
  end

  describe '#pick_build!' do
    let_it_be(:runner) { create(:ci_runner) }

    let(:build) { FactoryBot.build(:ci_build) }

    context 'runner can pick the build' do
      it 'calls #tick_runner_queue' do
        expect(runner).to receive(:tick_runner_queue)

        runner.pick_build!(build)
      end
    end

    context 'runner cannot pick the build' do
      before do
        build.tag_list = [:docker]
      end

      it 'does not call #tick_runner_queue' do
        expect(runner).not_to receive(:tick_runner_queue)

        runner.pick_build!(build)
      end
    end
  end

  describe 'project runner without projects is destroyable' do
    let!(:runner) { create(:ci_runner, :project, :without_projects) }

    subject(:destroy!) { runner.destroy! }

    it 'does not have projects' do
      expect(runner.runner_projects).to be_empty
    end

    it 'can be destroyed' do
      expect { destroy! }.to change { described_class.count }.by(-1)
    end
  end

  describe '.order_by' do
    let_it_be(:runner1) { create(:ci_runner, created_at: 1.year.ago, contacted_at: 1.year.ago) }
    let_it_be(:runner2) { create(:ci_runner, created_at: 1.month.ago, contacted_at: 1.month.ago) }

    before do
      runner1.update!(token_expires_at: 1.year.from_now)
    end

    it 'supports ordering by the contact date' do
      runners = described_class.order_by('contacted_asc')

      expect(runners).to eq([runner1, runner2])
    end

    it 'supports ordering by the creation date' do
      runners = described_class.order_by('created_asc')

      expect(runners).to eq([runner2, runner1])
    end

    it 'supports ordering by the token expiration' do
      runner3 = create(:ci_runner)
      runner3.update!(token_expires_at: 1.month.from_now)

      runners = described_class.order_by('token_expires_at_asc')
      expect(runners).to eq([runner3, runner1, runner2])

      runners = described_class.order_by('token_expires_at_desc')
      expect(runners).to eq([runner2, runner1, runner3])
    end
  end

  describe '.runner_matchers' do
    subject(:matchers) { described_class.all.runner_matchers }

    context 'deduplicates on runner_type' do
      before do
        create_list(:ci_runner, 2, :instance)
        create_list(:ci_runner, 2, :project, projects: [project])
      end

      it 'creates two matchers' do
        expect(matchers.size).to eq(2)

        expect(matchers.map(&:runner_type)).to match_array(%w[instance_type project_type])
      end
    end

    context 'deduplicates on public_projects_minutes_cost_factor' do
      before do
        create_list(:ci_runner, 2, public_projects_minutes_cost_factor: 5)
        create_list(:ci_runner, 2, public_projects_minutes_cost_factor: 10)
      end

      it 'creates two matchers' do
        expect(matchers.size).to eq(2)

        expect(matchers.map(&:public_projects_minutes_cost_factor)).to match_array([5, 10])
      end
    end

    context 'deduplicates on private_projects_minutes_cost_factor' do
      before do
        create_list(:ci_runner, 2, private_projects_minutes_cost_factor: 5)
        create_list(:ci_runner, 2, private_projects_minutes_cost_factor: 10)
      end

      it 'creates two matchers' do
        expect(matchers.size).to eq(2)

        expect(matchers.map(&:private_projects_minutes_cost_factor)).to match_array([5, 10])
      end
    end

    context 'deduplicates on run_untagged' do
      before do
        create_list(:ci_runner, 2, run_untagged: true, tag_list: ['a'])
        create_list(:ci_runner, 2, run_untagged: false, tag_list: ['a'])
      end

      it 'creates two matchers' do
        expect(matchers.size).to eq(2)

        expect(matchers.map(&:run_untagged)).to match_array([true, false])
      end
    end

    context 'deduplicates on access_level' do
      before do
        create_list(:ci_runner, 2, access_level: :ref_protected)
        create_list(:ci_runner, 2, access_level: :not_protected)
      end

      it 'creates two matchers' do
        expect(matchers.size).to eq(2)

        expect(matchers.map(&:access_level)).to match_array(%w[ref_protected not_protected])
      end
    end

    context 'deduplicates on tag_list' do
      before do
        create_list(:ci_runner, 2, tag_list: %w[tag1 tag2])
        create_list(:ci_runner, 2, tag_list: %w[tag3 tag4])
      end

      it 'creates two matchers' do
        expect(matchers.size).to eq(2)

        expect(matchers.map(&:tag_list)).to match_array([%w[tag1 tag2], %w[tag3 tag4]])
      end
    end

    context 'deduplicates on allowed_plan_ids' do
      before do
        create_list(:ci_runner, 2, allowed_plan_ids: [1, 2])
        create_list(:ci_runner, 2, allowed_plan_ids: [3, 4])
      end

      it 'creates two matchers' do
        expect(matchers.size).to eq(2)

        expect(matchers.map(&:allowed_plan_ids)).to match_array([[1, 2], [3, 4]])
      end
    end

    context 'with runner_ids' do
      before do
        create_list(:ci_runner, 2)
      end

      it 'includes runner_ids' do
        expect(matchers.size).to eq(1)

        expect(matchers.first.runner_ids).to match_array(described_class.all.ids)
      end
    end
  end

  describe '#runner_matcher' do
    let(:runner) do
      build_stubbed(:ci_runner, tag_list: %w[tag1 tag2], allowed_plan_ids: [1, 2])
    end

    subject(:matcher) { runner.runner_matcher }

    it { expect(matcher.runner_ids).to eq([runner.id]) }

    it { expect(matcher.runner_type).to eq(runner.runner_type) }

    it { expect(matcher.public_projects_minutes_cost_factor).to eq(runner.public_projects_minutes_cost_factor) }

    it { expect(matcher.private_projects_minutes_cost_factor).to eq(runner.private_projects_minutes_cost_factor) }

    it { expect(matcher.run_untagged).to eq(runner.run_untagged) }

    it { expect(matcher.access_level).to eq(runner.access_level) }

    it { expect(matcher.tag_list).to match_array(runner.tag_list) }

    it { expect(matcher.allowed_plan_ids).to match_array(runner.allowed_plan_ids) }
  end

  describe '#uncached_contacted_at' do
    let(:contacted_at_stored) { 1.hour.ago.change(usec: 0) }
    let(:runner) { create(:ci_runner, contacted_at: contacted_at_stored) }

    subject { runner.uncached_contacted_at }

    it { is_expected.to eq(contacted_at_stored) }
  end

  describe 'Group-related queries' do
    # Groups
    let_it_be(:top_level_group) { create(:group) }
    let_it_be(:child_group) { create(:group, parent: top_level_group) }
    let_it_be(:child_group2) { create(:group, parent: top_level_group) }
    let_it_be(:other_top_level_group) { create(:group) }

    # Projects
    let_it_be(:top_level_group_project) { create(:project, group: top_level_group) }
    let_it_be(:child_group_project) { create(:project, group: child_group) }
    let_it_be(:other_top_level_group_project) { create(:project, group: other_top_level_group) }

    # Runners
    let_it_be(:instance_runner) { create(:ci_runner, :instance) }
    let_it_be(:top_level_group_runner) { create(:ci_runner, :group, groups: [top_level_group]) }
    let_it_be(:child_group_runner) { create(:ci_runner, :group, groups: [child_group]) }
    let_it_be(:child_group2_runner) { create(:ci_runner, :group, groups: [child_group2]) }
    let_it_be(:other_top_level_group_runner) do
      create(:ci_runner, :group, groups: [other_top_level_group])
    end

    let_it_be(:top_level_group_project_runner) do
      create(:ci_runner, :project, projects: [top_level_group_project])
    end

    let_it_be(:child_group_project_runner) do
      create(:ci_runner, :project, projects: [child_group_project])
    end

    let_it_be(:other_top_level_group_project_runner) do
      create(:ci_runner, :project, projects: [other_top_level_group_project])
    end

    let_it_be(:shared_top_level_group_project_runner) do
      create(:ci_runner, :project, projects: [top_level_group_project, child_group_project])
    end

    describe '.belonging_to_group' do
      subject(:relation) { described_class.belonging_to_group(scope.id) }

      context 'with scope set to top_level_group' do
        let(:scope) { top_level_group }

        it 'returns the group runners from the top_level_group' do
          is_expected.to contain_exactly(top_level_group_runner)
        end
      end

      context 'with scope set to child_group' do
        let(:scope) { child_group }

        it 'returns the group runners from the child_group' do
          is_expected.to contain_exactly(child_group_runner)
        end
      end
    end

    describe '.belonging_to_group_and_ancestors' do
      subject(:relation) { described_class.belonging_to_group_and_ancestors(child_group.id) }

      it 'returns the group runners from the group and parent group' do
        is_expected.to contain_exactly(child_group_runner, top_level_group_runner)
      end
    end

    describe '.belonging_to_group_or_project_descendants' do
      subject(:relation) { described_class.belonging_to_group_or_project_descendants(scope.id) }

      context 'with scope set to top_level_group' do
        let(:scope) { top_level_group }

        it 'returns the expected group and project runners without duplicates', :aggregate_failures do
          expect(relation).to contain_exactly(
            top_level_group_runner,
            top_level_group_project_runner,
            child_group_runner,
            child_group_project_runner,
            child_group2_runner,
            shared_top_level_group_project_runner
          )

          # Ensure no duplicates are returned
          expect(relation.distinct).to match_array(relation)
        end
      end

      context 'with scope set to child_group' do
        let(:scope) { child_group }

        it 'returns the expected group and project runners without duplicates', :aggregate_failures do
          expect(relation).to contain_exactly(
            child_group_runner,
            child_group_project_runner,
            shared_top_level_group_project_runner
          )

          # Ensure no duplicates are returned
          expect(relation.distinct).to match_array(relation)
        end
      end
    end

    describe '.usable_from_scope' do
      subject(:relation) { described_class.usable_from_scope(scope) }

      context 'with scope set to top_level_group' do
        let(:scope) { top_level_group }

        it 'returns all runners usable from top_level_group without duplicates' do
          expect(relation).to contain_exactly(
            instance_runner,
            top_level_group_runner,
            top_level_group_project_runner,
            child_group_runner,
            child_group_project_runner,
            child_group2_runner,
            shared_top_level_group_project_runner
          )

          # Ensure no duplicates are returned
          expect(relation.distinct).to match_array(relation)
        end
      end

      context 'with scope set to child_group' do
        let(:scope) { child_group }

        it 'returns all runners usable from child_group' do
          expect(relation).to contain_exactly(
            instance_runner,
            top_level_group_runner,
            child_group_runner,
            child_group_project_runner,
            shared_top_level_group_project_runner
          )
        end
      end

      context 'with scope set to other_top_level_group' do
        let(:scope) { other_top_level_group }

        it 'returns all runners usable from other_top_level_group' do
          expect(relation).to contain_exactly(
            instance_runner,
            other_top_level_group_runner,
            other_top_level_group_project_runner
          )
        end
      end
    end

    describe '#owner' do
      subject(:owner) { runner.owner }

      let_it_be_with_refind(:runner) { create(:ci_runner, :group, groups: [group]) }

      it { is_expected.to eq group }

      context 'when sharding_key_id points to non-existing group' do
        before do
          runner.update_columns(sharding_key_id: non_existing_record_id)
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#short_sha' do
    subject(:short_sha) { runner.short_sha }

    context 'when registered via command-line' do
      let_it_be(:runner) { create(:ci_runner) }

      specify { expect(runner.token).not_to start_with(described_class::CREATED_RUNNER_TOKEN_PREFIX) }
      it { is_expected.to match(/[0-9a-zA-Z_-]{8}/) }
      it { is_expected.not_to start_with('t1_') }
      it { is_expected.not_to start_with(described_class::CREATED_RUNNER_TOKEN_PREFIX) }
    end

    context 'when creating new runner via UI' do
      let_it_be(:runner) { create(:ci_runner, registration_type: :authenticated_user) }

      specify { expect(runner.token).to start_with(described_class::CREATED_RUNNER_TOKEN_PREFIX) }
      it { is_expected.to match(/[0-9a-zA-Z_-]{8}/) }
      it { is_expected.not_to start_with('t1_') }
      it { is_expected.not_to start_with(described_class::CREATED_RUNNER_TOKEN_PREFIX) }
    end
  end

  describe '#token' do
    subject(:token) { runner.token }

    let(:runner_type) { :instance_type }
    let(:attrs) { {} }
    let(:runner) { create(:ci_runner, runner_type, registration_type: registration_type, **attrs) }

    context 'when runner is registered' do
      let(:registration_type) { :registration_token }

      it { is_expected.not_to start_with('glrt-') }
      it { is_expected.to start_with('t1_') }

      context 'when runner is group type' do
        let(:runner_type) { :group_type }
        let(:attrs) { { groups: [group] } }

        it { is_expected.to start_with('t2_') }
      end

      context 'when runner is project type' do
        let(:runner_type) { :project_type }
        let(:attrs) { { projects: [project] } }

        it { is_expected.to start_with('t3_') }
      end
    end

    context 'when runner is created via UI' do
      let(:registration_type) { :authenticated_user }

      it { is_expected.to start_with('glrt-t1_') }

      context 'when runner is group type' do
        let(:runner_type) { :group_type }
        let(:attrs) { { groups: [group] } }

        it { is_expected.to start_with('glrt-t2_') }
      end

      context 'when runner is project type' do
        let(:runner_type) { :project_type }
        let(:attrs) { { projects: [project] } }

        it { is_expected.to start_with('glrt-t3_') }
      end
    end
  end

  describe '#token_expires_at', :freeze_time do
    let_it_be(:group_settings) { create(:namespace_settings, runner_token_expiration_interval: 6.days.to_i) }
    let_it_be(:group_with_expiration) { create(:group, namespace_settings: group_settings) }
    let_it_be(:existing_runner) { create(:ci_runner) }

    shared_examples 'expiring token' do |interval:|
      it 'expires' do
        expect(runner.token_expires_at).to eq(interval.from_now)
      end
    end

    shared_examples 'non-expiring token' do
      it 'does not expire' do
        expect(runner.token_expires_at).to be_nil
      end
    end

    context 'no expiration' do
      let(:runner) { existing_runner }

      it_behaves_like 'non-expiring token'
    end

    context 'system-wide shared expiration' do
      before do
        stub_application_setting(runner_token_expiration_interval: 5.days.to_i)
      end

      let(:runner) { create(:ci_runner) }

      it_behaves_like 'expiring token', interval: 5.days
    end

    context 'system-wide group expiration' do
      before do
        stub_application_setting(group_runner_token_expiration_interval: 5.days.to_i)
      end

      let(:runner) { existing_runner }

      it_behaves_like 'non-expiring token'
    end

    context 'system-wide project expiration' do
      before do
        stub_application_setting(project_runner_token_expiration_interval: 5.days.to_i)
      end

      let(:runner) { existing_runner }

      it_behaves_like 'non-expiring token'
    end

    context 'group expiration' do
      let(:runner) { create(:ci_runner, :group, groups: [group_with_expiration]) }

      it_behaves_like 'expiring token', interval: 6.days

      context 'with human-readable group expiration' do
        before do
          group_with_expiration.runner_token_expiration_interval_human_readable = '7 days'
          group_with_expiration.save!
        end

        it_behaves_like 'expiring token', interval: 7.days
      end

      context 'group overrides system' do
        before do
          stub_application_setting(group_runner_token_expiration_interval: 7.days.to_i)
        end

        it_behaves_like 'expiring token', interval: 6.days
      end

      context 'system overrides group' do
        before do
          stub_application_setting(group_runner_token_expiration_interval: 3.days.to_i)
        end

        it_behaves_like 'expiring token', interval: 3.days
      end
    end

    context 'project expiration' do
      let_it_be(:project) { create(:project, group: group, runner_token_expiration_interval: 4.days.to_i) }
      let(:runner) { create(:ci_runner, :project, projects: [project]) }

      it_behaves_like 'expiring token', interval: 4.days

      context 'human-readable project expiration' do
        before do
          project.runner_token_expiration_interval_human_readable = '5 days'
          project.save!
        end

        it_behaves_like 'expiring token', interval: 5.days
      end

      context 'with multiple projects' do
        let_it_be(:project2) { create(:project, runner_token_expiration_interval: 3.days.to_i) }
        let_it_be(:project3) { create(:project, runner_token_expiration_interval: 9.days.to_i) }
        let(:runner) { create(:ci_runner, :project, projects: [project, project2, project3]) }

        it_behaves_like 'expiring token', interval: 3.days
      end

      context 'when project overrides system' do
        before do
          stub_application_setting(project_runner_token_expiration_interval: 5.days.to_i)
        end

        it_behaves_like 'expiring token', interval: 4.days
      end

      context 'when system overrides project' do
        before do
          stub_application_setting(project_runner_token_expiration_interval: 3.days.to_i)
        end

        it_behaves_like 'expiring token', interval: 3.days
      end
    end

    context "with group's project runner token expiring" do
      let_it_be(:parent_group_settings) { create(:namespace_settings, subgroup_runner_token_expiration_interval: 2.days.to_i) }
      let_it_be(:parent_group) { create(:group, namespace_settings: parent_group_settings) }
      let_it_be(:group_settings) { create(:namespace_settings) }
      let_it_be(:group) { create(:group, parent: parent_group, namespace_settings: group_settings) }

      let(:runner) { create(:ci_runner, :group, groups: [group]) }

      context 'parent group overrides subgroup' do
        before_all do
          group.runner_token_expiration_interval = 3.days.to_i
          group.save!
        end

        it_behaves_like 'expiring token', interval: 2.days
      end

      context 'subgroup overrides parent group' do
        before_all do
          group.runner_token_expiration_interval = 1.day.to_i
          group.save!
        end

        it_behaves_like 'expiring token', interval: 1.day
      end
    end

    context "with group's project runner token expiring" do
      let_it_be(:project) { create(:project, group: group_with_expiration) }

      let(:runner) { create(:ci_runner, :project, projects: [project]) }

      before_all do
        group_with_expiration.project_runner_token_expiration_interval = 2.days.to_i
        group_with_expiration.save!
      end

      context 'group overrides project' do
        before do
          project.runner_token_expiration_interval = 3.days.to_i
          project.save!
        end

        it_behaves_like 'expiring token', interval: 2.days
      end

      context 'project overrides group' do
        before do
          project.runner_token_expiration_interval = 1.day.to_i
          project.save!
        end

        it_behaves_like 'expiring token', interval: 1.day
      end
    end
  end

  describe '.with_upgrade_status' do
    subject(:scope) { described_class.with_upgrade_status(upgrade_status) }

    let_it_be(:runner_14_0_0) { create(:ci_runner) }
    let_it_be(:runner_14_1_0_and_14_0_0) { create(:ci_runner) }
    let_it_be(:runner_14_1_0) { create(:ci_runner) }
    let_it_be(:runner_14_1_1) { create(:ci_runner) }

    before_all do
      create(:ci_runner_machine, runner: runner_14_1_0_and_14_0_0, version: '14.0.0')
      create(:ci_runner_machine, runner: runner_14_1_0_and_14_0_0, version: '14.1.0')
      create(:ci_runner_machine, runner: runner_14_0_0, version: '14.0.0')
      create(:ci_runner_machine, runner: runner_14_1_0, version: '14.1.0')
      create(:ci_runner_machine, runner: runner_14_1_1, version: '14.1.1')

      create(:ci_runner_version, version: '14.0.0', status: :available)
      create(:ci_runner_version, version: '14.1.0', status: :recommended)
      create(:ci_runner_version, version: '14.1.1', status: :unavailable)
    end

    context ':unavailable' do
      let(:upgrade_status) { :unavailable }

      it 'returns runners with runner managers whose version is assigned :unavailable' do
        is_expected.to contain_exactly(runner_14_1_1)
      end
    end

    context ':available' do
      let(:upgrade_status) { :available }

      it 'returns runners with runner managers whose version is assigned :available' do
        is_expected.to contain_exactly(runner_14_0_0, runner_14_1_0_and_14_0_0)
      end
    end

    context ':recommended' do
      let(:upgrade_status) { :recommended }

      it 'returns runners with runner managers whose version is assigned :recommended' do
        is_expected.to contain_exactly(runner_14_1_0_and_14_0_0, runner_14_1_0)
      end
    end

    describe 'composed with other scopes' do
      subject { described_class.active(false).with_upgrade_status(:available) }

      before do
        create(:ci_runner_machine, runner: paused_runner_14_0_0, version: '14.0.0')
      end

      let(:paused_runner_14_0_0) { create(:ci_runner, :paused) }

      it 'returns runner matching the composed scope' do
        is_expected.to contain_exactly(paused_runner_14_0_0)
      end
    end
  end

  describe '.with_creator' do
    subject { described_class.with_creator }

    let!(:user) { create(:admin) }
    let!(:runner) { create(:ci_runner, creator: user) }

    it { is_expected.to contain_exactly(runner) }
  end

  describe '#ensure_token' do
    let(:runner) { build(:ci_runner, registration_type: registration_type) }
    let(:token) { 'an_existing_secret_token' }
    let(:static_prefix) { described_class::CREATED_RUNNER_TOKEN_PREFIX }

    context 'when runner is initialized without a token' do
      context 'with registration_token' do
        let(:registration_type) { :registration_token }

        it 'generates a token' do
          expect { runner.ensure_token }.to change { runner.token }.from(nil)
        end
      end

      context 'with authenticated_user' do
        let(:registration_type) { :authenticated_user }

        it 'generates a token with prefix' do
          expect { runner.ensure_token }.to change { runner.token }.from(nil).to(a_string_starting_with(static_prefix))
        end
      end
    end

    context 'when runner is initialized with a token' do
      before do
        runner.set_token(token)
      end

      context 'with registration_token' do
        let(:registration_type) { :registration_token }

        it 'does not change the existing token' do
          expect { runner.ensure_token }.not_to change { runner.token }.from(token)
        end
      end

      context 'with authenticated_user' do
        let(:registration_type) { :authenticated_user }

        it 'does not change the existing token' do
          expect { runner.ensure_token }.not_to change { runner.token }.from(token)
        end
      end
    end
  end

  describe '#gitlab_hosted?' do
    using RSpec::Parameterized::TableSyntax

    subject(:runner) { build_stubbed(:ci_runner) }

    where(:saas, :runner_type, :expected_value) do
      true  | :instance_type | true
      true  | :group_type    | false
      true  | :project_type  | false
      false | :instance_type | false
      false | :group_type    | false
      false | :project_type  | false
    end

    with_them do
      before do
        allow(Gitlab).to receive(:com?).and_return(saas)
        runner.runner_type = runner_type
      end

      it 'returns the correct value based on saas and runner type' do
        expect(runner.gitlab_hosted?).to eq(expected_value)
      end
    end
  end

  describe 'status scopes', :freeze_time do
    before_all do
      freeze_time # Freeze time before `let_it_be` runs, so that runner statuses are frozen during execution
    end

    after :all do
      unfreeze_time
    end

    let_it_be(:online_runner) { create(:ci_runner, :instance, :almost_offline) }
    let_it_be(:offline_runner) { create(:ci_runner, :instance, :offline) }
    let_it_be(:never_contacted_runner) { create(:ci_runner, :instance, :unregistered) }

    describe '.online' do
      subject(:runners) { described_class.online }

      it 'returns online runners' do
        expect(runners).to contain_exactly(online_runner)
      end
    end

    describe '.offline' do
      subject(:runners) { described_class.offline }

      it 'returns offline runners' do
        expect(runners).to contain_exactly(offline_runner)
      end
    end

    describe '.never_contacted' do
      subject(:runners) { described_class.never_contacted }

      it 'returns never contacted runners' do
        expect(runners).to contain_exactly(never_contacted_runner)
      end
    end

    describe '.stale' do
      subject { described_class.stale }

      let!(:stale_runner1) { create(:ci_runner, :unregistered, :stale) }
      let!(:stale_runner2) { create(:ci_runner, :stale) }

      it 'returns stale runners' do
        is_expected.to contain_exactly(stale_runner1, stale_runner2)
      end
    end

    include_examples 'runner with status scope'
  end

  describe '.available_statuses' do
    subject { described_class.available_statuses }

    it { is_expected.to eq(%w[active paused online offline never_contacted stale]) }
  end

  describe '.online_contact_time_deadline', :freeze_time do
    subject { described_class.online_contact_time_deadline }

    it { is_expected.to eq(2.hours.ago) }
  end

  describe '.stale_deadline', :freeze_time do
    subject { described_class.stale_deadline }

    it { is_expected.to eq(7.days.ago) }
  end

  describe '.with_runner_type' do
    subject { described_class.with_runner_type(runner_type) }

    let_it_be(:instance_runner) { create(:ci_runner, :instance) }
    let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }
    let_it_be(:project_runner) { create(:ci_runner, :project, :without_projects) }

    context 'with instance_type' do
      let(:runner_type) { 'instance_type' }

      it { is_expected.to contain_exactly(instance_runner) }
    end

    context 'with group_type' do
      let(:runner_type) { 'group_type' }

      it { is_expected.to contain_exactly(group_runner) }
    end

    context 'with project_type' do
      let(:runner_type) { 'project_type' }

      it { is_expected.to contain_exactly(project_runner) }
    end

    context 'with invalid runner type' do
      let(:runner_type) { 'invalid runner type' }

      it { is_expected.to contain_exactly(instance_runner, group_runner, project_runner) }
    end
  end

  describe '.with_sharding_key' do
    subject(:scope) { described_class.with_runner_type(runner_type).with_sharding_key(sharding_key_id) }

    let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }
    let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project, other_project]) }

    context 'with group_type' do
      let(:runner_type) { 'group_type' }

      context 'when sharding_key_id exists' do
        let(:sharding_key_id) { group.id }

        it { is_expected.to contain_exactly(group_runner) }
      end

      context 'when sharding_key_id does not exist' do
        let(:sharding_key_id) { non_existing_record_id }

        it { is_expected.to eq [] }
      end
    end

    context 'with project_type' do
      let(:runner_type) { 'project_type' }

      context 'when sharding_key_id exists' do
        let(:sharding_key_id) { project.id }

        it { is_expected.to contain_exactly(project_runner) }
      end

      context 'when sharding_key_id does not exist' do
        let(:sharding_key_id) { non_existing_record_id }

        it { is_expected.to eq [] }
      end
    end
  end
end
