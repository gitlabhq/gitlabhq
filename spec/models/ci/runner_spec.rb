# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runner do
  it_behaves_like 'having unique enum values'

  describe 'validation' do
    it { is_expected.to validate_presence_of(:access_level) }
    it { is_expected.to validate_presence_of(:runner_type) }

    context 'when runner is not allowed to pick untagged jobs' do
      context 'when runner does not have tags' do
        it 'is not valid' do
          runner = build(:ci_runner, tag_list: [], run_untagged: false)
          expect(runner).to be_invalid
        end
      end

      context 'when runner has tags' do
        it 'is valid' do
          runner = build(:ci_runner, tag_list: ['tag'], run_untagged: false)
          expect(runner).to be_valid
        end
      end
    end

    describe '#exactly_one_group' do
      let(:group) { create(:group) }
      let(:runner) { create(:ci_runner, :group, groups: [group]) }

      it 'disallows assigning group if already assigned to a group' do
        runner.groups << build(:group)

        expect(runner).not_to be_valid
        expect(runner.errors.full_messages).to include('Runner needs to be assigned to exactly one group')
      end
    end

    context 'runner_type validations' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project) }

      it 'disallows assigning group to project_type runner' do
        project_runner = build(:ci_runner, :project, groups: [group])

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

      context 'when runner has config' do
        it 'is valid' do
          runner = build(:ci_runner, config: { gpus: "all" })

          expect(runner).to be_valid
        end
      end

      context 'when runner has an invalid config' do
        it 'is invalid' do
          runner = build(:ci_runner, config: { test: 1 })

          expect(runner).not_to be_valid
        end
      end
    end

    context 'cost factors validations' do
      it 'dissalows :private_projects_minutes_cost_factor being nil' do
        runner = build(:ci_runner, private_projects_minutes_cost_factor: nil)

        expect(runner).to be_invalid
        expect(runner.errors.full_messages).to include('Private projects minutes cost factor needs to be non-negative')
      end

      it 'dissalows :public_projects_minutes_cost_factor being nil' do
        runner = build(:ci_runner, public_projects_minutes_cost_factor: nil)

        expect(runner).to be_invalid
        expect(runner.errors.full_messages).to include('Public projects minutes cost factor needs to be non-negative')
      end

      it 'dissalows :private_projects_minutes_cost_factor being negative' do
        runner = build(:ci_runner, private_projects_minutes_cost_factor: -1.1)

        expect(runner).to be_invalid
        expect(runner.errors.full_messages).to include('Private projects minutes cost factor needs to be non-negative')
      end

      it 'dissalows :public_projects_minutes_cost_factor being negative' do
        runner = build(:ci_runner, public_projects_minutes_cost_factor: -2.2)

        expect(runner).to be_invalid
        expect(runner.errors.full_messages).to include('Public projects minutes cost factor needs to be non-negative')
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
      let(:runner) do
        build(:ci_runner, access_level: nil)
      end

      it "object is invalid" do
        expect(runner).not_to be_valid
      end
    end

    context 'when creating new runner and access_level is defined in enum' do
      let(:runner) do
        build(:ci_runner, access_level: :not_protected)
      end

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

  describe '.instance_type' do
    let(:group) { create(:group) }
    let(:project) { create(:project) }
    let!(:group_runner) { create(:ci_runner, :group, groups: [group]) }
    let!(:project_runner) { create(:ci_runner, :project, projects: [project]) }
    let!(:shared_runner) { create(:ci_runner, :instance) }

    it 'returns only shared runners' do
      expect(described_class.instance_type).to contain_exactly(shared_runner)
    end
  end

  describe '.belonging_to_project' do
    it 'returns the specific project runner' do
      # own
      specific_project = create(:project)
      specific_runner = create(:ci_runner, :project, projects: [specific_project])

      # other
      other_project = create(:project)
      create(:ci_runner, :project, projects: [other_project])

      expect(described_class.belonging_to_project(specific_project.id)).to eq [specific_runner]
    end
  end

  describe '.belonging_to_parent_group_of_project' do
    let(:project) { create(:project, group: group) }
    let(:group) { create(:group) }
    let(:runner) { create(:ci_runner, :group, groups: [group]) }
    let!(:unrelated_group) { create(:group) }
    let!(:unrelated_project) { create(:project, group: unrelated_group) }
    let!(:unrelated_runner) { create(:ci_runner, :group, groups: [unrelated_group]) }

    it 'returns the specific group runner' do
      expect(described_class.belonging_to_parent_group_of_project(project.id)).to contain_exactly(runner)
    end

    context 'with a parent group with a runner' do
      let(:runner) { create(:ci_runner, :group, groups: [parent_group]) }
      let(:project) { create(:project, group: group) }
      let(:group) { create(:group, parent: parent_group) }
      let(:parent_group) { create(:group) }

      it 'returns the group runner from the parent group' do
        expect(described_class.belonging_to_parent_group_of_project(project.id)).to contain_exactly(runner)
      end
    end
  end

  describe '.owned_or_instance_wide' do
    it 'returns a globally shared, a project specific and a group specific runner' do
      # group specific
      group = create(:group)
      project = create(:project, group: group)
      group_runner = create(:ci_runner, :group, groups: [group])

      # project specific
      project_runner = create(:ci_runner, :project, projects: [project])

      # globally shared
      shared_runner = create(:ci_runner, :instance)

      expect(described_class.owned_or_instance_wide(project.id)).to contain_exactly(
        group_runner, project_runner, shared_runner
      )
    end
  end

  describe '#display_name' do
    it 'returns the description if it has a value' do
      runner = build(:ci_runner, description: 'Linux/Ruby-1.9.3-p448')
      expect(runner.display_name).to eq 'Linux/Ruby-1.9.3-p448'
    end

    it 'returns the token if it does not have a description' do
      runner = create(:ci_runner)
      expect(runner.display_name).to eq runner.description
    end

    it 'returns the token if the description is an empty string' do
      runner = build(:ci_runner, description: '', token: 'token')
      expect(runner.display_name).to eq runner.token
    end
  end

  describe '#assign_to' do
    let(:project) { create(:project) }

    subject { runner.assign_to(project) }

    context 'with shared_runner' do
      let(:runner) { create(:ci_runner, :instance) }

      it 'transitions shared runner to project runner and assigns project' do
        expect(subject).to be_truthy

        expect(runner).to be_project_type
        expect(runner.projects).to eq([project])
        expect(runner.only_for?(project)).to be_truthy
      end
    end

    context 'with group runner' do
      let(:group) { create(:group) }
      let(:runner) { create(:ci_runner, :group, groups: [group]) }

      it 'raises an error' do
        expect { subject }
          .to raise_error(ArgumentError, 'Transitioning a group runner to a project runner is not supported')
      end
    end
  end

  describe '.recent' do
    subject { described_class.recent }

    before do
      @runner1 = create(:ci_runner, :instance, contacted_at: nil, created_at: 2.months.ago)
      @runner2 = create(:ci_runner, :instance, contacted_at: nil, created_at: 3.months.ago)
      @runner3 = create(:ci_runner, :instance, contacted_at: 1.month.ago, created_at: 2.months.ago)
      @runner4 = create(:ci_runner, :instance, contacted_at: 1.month.ago, created_at: 3.months.ago)
      @runner5 = create(:ci_runner, :instance, contacted_at: 3.months.ago, created_at: 5.months.ago)
    end

    it { is_expected.to eq([@runner1, @runner3, @runner4])}
  end

  describe '.online' do
    subject { described_class.online }

    before do
      @runner1 = create(:ci_runner, :instance, contacted_at: 2.hours.ago)
      @runner2 = create(:ci_runner, :instance, contacted_at: 1.second.ago)
    end

    it { is_expected.to eq([@runner2])}
  end

  describe '#online?', :clean_gitlab_redis_cache do
    let(:runner) { create(:ci_runner, :instance) }

    subject { runner.online? }

    before do
      allow_any_instance_of(described_class).to receive(:cached_attribute).and_call_original
      allow_any_instance_of(described_class).to receive(:cached_attribute)
        .with(:platform).and_return("darwin")
    end

    context 'no cache value' do
      before do
        stub_redis_runner_contacted_at(nil)
      end

      context 'never contacted' do
        before do
          runner.contacted_at = nil
        end

        it { is_expected.to be_falsey }
      end

      context 'contacted long time ago time' do
        before do
          runner.contacted_at = 1.year.ago
        end

        it { is_expected.to be_falsey }
      end

      context 'contacted 1s ago' do
        before do
          runner.contacted_at = 1.second.ago
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'with cache value' do
      context 'contacted long time ago time' do
        before do
          runner.contacted_at = 1.year.ago
          stub_redis_runner_contacted_at(1.year.ago.to_s)
        end

        it { is_expected.to be_falsey }
      end

      context 'contacted 1s ago' do
        before do
          runner.contacted_at = 50.minutes.ago
          stub_redis_runner_contacted_at(1.second.ago.to_s)
        end

        it { is_expected.to be_truthy }
      end
    end

    def stub_redis_runner_contacted_at(value)
      Gitlab::Redis::Cache.with do |redis|
        cache_key = runner.send(:cache_attribute_key)
        expect(redis).to receive(:get).with(cache_key)
          .and_return({ contacted_at: value }.to_json).at_least(:once)
      end
    end
  end

  describe '.offline' do
    subject { described_class.offline }

    before do
      @runner1 = create(:ci_runner, :instance, contacted_at: 2.hours.ago)
      @runner2 = create(:ci_runner, :instance, contacted_at: 1.second.ago)
    end

    it { is_expected.to eq([@runner1])}
  end

  describe '#tick_runner_queue' do
    it 'sticks the runner to the primary and calls the original method' do
      runner = create(:ci_runner)

      allow(Gitlab::Database::LoadBalancing).to receive(:enable?)
        .and_return(true)

      expect(Gitlab::Database::LoadBalancing::Sticking).to receive(:stick)
        .with(:runner, runner.id)

      expect(Gitlab::Workhorse).to receive(:set_key_and_notify)

      runner.tick_runner_queue
    end
  end

  describe '#can_pick?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:pipeline) { create(:ci_pipeline) }

    let(:build) { create(:ci_build, pipeline: pipeline) }
    let(:runner_project) { build.project }
    let(:runner) { create(:ci_runner, :project, projects: [runner_project], tag_list: tag_list, run_untagged: run_untagged) }
    let(:tag_list) { [] }
    let(:run_untagged) { true }

    subject { runner.can_pick?(build) }

    context 'a different runner' do
      let(:other_project) { create(:project) }
      let(:other_runner) { create(:ci_runner, :project, projects: [other_project], tag_list: tag_list, run_untagged: run_untagged) }

      before do
        # `can_pick?` is not used outside the runners available for the project
        stub_feature_flags(ci_runners_short_circuit_assignable_for: false)
      end

      it 'cannot handle builds' do
        expect(other_runner.can_pick?(build)).to be_falsey
      end
    end

    context 'when runner does not have tags' do
      it 'can handle builds without tags' do
        expect(runner.can_pick?(build)).to be_truthy
      end

      it 'cannot handle build with tags' do
        build.tag_list = ['aa']

        expect(runner.can_pick?(build)).to be_falsey
      end
    end

    context 'when runner has tags' do
      let(:tag_list) { %w(bb cc) }

      shared_examples 'tagged build picker' do
        it 'can handle build with matching tags' do
          build.tag_list = ['bb']

          expect(runner.can_pick?(build)).to be_truthy
        end

        it 'cannot handle build without matching tags' do
          build.tag_list = ['aa']

          expect(runner.can_pick?(build)).to be_falsey
        end
      end

      context 'when runner can pick untagged jobs' do
        it 'can handle builds without tags' do
          expect(runner.can_pick?(build)).to be_truthy
        end

        it_behaves_like 'tagged build picker'
      end

      context 'when runner cannot pick untagged jobs' do
        let(:run_untagged) { false }

        it 'cannot handle builds without tags' do
          expect(runner.can_pick?(build)).to be_falsey
        end

        it_behaves_like 'tagged build picker'
      end
    end

    context 'when runner is shared' do
      let(:runner) { create(:ci_runner, :instance) }

      it 'can handle builds' do
        expect(runner.can_pick?(build)).to be_truthy
      end

      context 'when runner is locked' do
        let(:runner) { create(:ci_runner, :instance, locked: true) }

        it 'can handle builds' do
          expect(runner.can_pick?(build)).to be_truthy
        end
      end

      it 'does not query for owned or instance runners' do
        expect(described_class).not_to receive(:owned_or_instance_wide)

        runner.can_pick?(build)
      end

      context 'when feature flag ci_runners_short_circuit_assignable_for is disabled' do
        before do
          stub_feature_flags(ci_runners_short_circuit_assignable_for: false)
        end

        it 'does not query for owned or instance runners' do
          expect(described_class).to receive(:owned_or_instance_wide).and_call_original

          runner.can_pick?(build)
        end
      end
    end

    context 'when runner is not shared' do
      before do
        # `can_pick?` is not used outside the runners available for the project
        stub_feature_flags(ci_runners_short_circuit_assignable_for: false)
      end

      context 'when runner is assigned to a project' do
        it 'can handle builds' do
          expect(runner.can_pick?(build)).to be_truthy
        end
      end

      context 'when runner is assigned to another project' do
        let(:runner_project) { create(:project) }

        it 'cannot handle builds' do
          expect(runner.can_pick?(build)).to be_falsey
        end
      end

      context 'when runner is assigned to a group' do
        let(:group) { create(:group, projects: [build.project]) }
        let(:runner) { create(:ci_runner, :group, tag_list: tag_list, run_untagged: run_untagged, groups: [group]) }

        it 'can handle builds' do
          expect(runner.can_pick?(build)).to be_truthy
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

  describe '#status' do
    let(:runner) { create(:ci_runner, :instance, contacted_at: 1.second.ago) }

    subject { runner.status }

    context 'never connected' do
      before do
        runner.contacted_at = nil
      end

      it { is_expected.to eq(:not_connected) }
    end

    context 'contacted 1s ago' do
      before do
        runner.contacted_at = 1.second.ago
      end

      it { is_expected.to eq(:online) }
    end

    context 'contacted long time ago' do
      before do
        runner.contacted_at = 1.year.ago
      end

      it { is_expected.to eq(:offline) }
    end

    context 'inactive' do
      before do
        runner.active = false
      end

      it { is_expected.to eq(:paused) }
    end
  end

  describe '#tick_runner_queue' do
    let(:runner) { create(:ci_runner) }

    it 'returns a new last_update value' do
      expect(runner.tick_runner_queue).not_to be_empty
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
        Ci::UpdateRunnerService.new(runner).update(description: 'new runner') # rubocop: disable Rails/SaveBang
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
      Gitlab::Redis::SharedState.with do |redis|
        runner_queue_key = runner.send(:runner_queue_key)
        redis.get(runner_queue_key)
      end
    end
  end

  describe '#heartbeat' do
    let(:runner) { create(:ci_runner, :project) }

    subject { runner.heartbeat(architecture: '18-bit', config: { gpus: "all" }) }

    context 'when database was updated recently' do
      before do
        runner.contacted_at = Time.current
      end

      it 'updates cache' do
        expect_redis_update

        subject
      end
    end

    context 'when database was not updated recently' do
      before do
        runner.contacted_at = 2.hours.ago
      end

      context 'with invalid runner' do
        before do
          runner.projects = []
        end

        it 'still updates redis cache and database' do
          expect(runner).to be_invalid

          expect_redis_update
          does_db_update
        end
      end

      it 'updates redis cache and database' do
        expect_redis_update
        does_db_update
      end
    end

    def expect_redis_update
      Gitlab::Redis::Cache.with do |redis|
        redis_key = runner.send(:cache_attribute_key)
        expect(redis).to receive(:set).with(redis_key, anything, any_args)
      end
    end

    def does_db_update
      expect { subject }.to change { runner.reload.read_attribute(:contacted_at) }
        .and change { runner.reload.read_attribute(:architecture) }
        .and change { runner.reload.read_attribute(:config) }
    end
  end

  describe '#destroy' do
    let(:runner) { create(:ci_runner) }

    context 'when there is a tick in the queue' do
      let!(:queue_key) { runner.send(:runner_queue_key) }

      before do
        runner.tick_runner_queue
        runner.destroy!
      end

      it 'cleans up the queue' do
        Gitlab::Redis::Cache.with do |redis|
          expect(redis.get(queue_key)).to be_nil
        end
      end
    end
  end

  describe '.assignable_for' do
    let(:project) { create(:project) }
    let(:group) { create(:group) }
    let(:another_project) { create(:project) }
    let!(:unlocked_project_runner) { create(:ci_runner, :project, projects: [project]) }
    let!(:locked_project_runner) { create(:ci_runner, :project, locked: true, projects: [project]) }
    let!(:group_runner) { create(:ci_runner, :group, groups: [group]) }
    let!(:instance_runner) { create(:ci_runner, :instance) }

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

  describe "belongs_to_one_project?" do
    it "returns false if there are two projects runner assigned to" do
      project1 = create(:project)
      project2 = create(:project)
      runner = create(:ci_runner, :project, projects: [project1, project2])

      expect(runner.belongs_to_one_project?).to be_falsey
    end

    it "returns true" do
      project = create(:project)
      runner = create(:ci_runner, :project, projects: [project])

      expect(runner.belongs_to_one_project?).to be_truthy
    end
  end

  describe '#belongs_to_more_than_one_project?' do
    context 'project runner' do
      let(:project1) { create(:project) }
      let(:project2) { create(:project) }

      context 'two projects assigned to runner' do
        let(:runner) { create(:ci_runner, :project, projects: [project1, project2]) }

        it 'returns true' do
          expect(runner.belongs_to_more_than_one_project?).to be_truthy
        end
      end

      context 'one project assigned to runner' do
        let(:runner) { create(:ci_runner, :project, projects: [project1]) }

        it 'returns false' do
          expect(runner.belongs_to_more_than_one_project?).to be_falsey
        end
      end
    end

    context 'group runner' do
      let(:group) { create(:group) }
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

  describe '#has_tags?' do
    context 'when runner has tags' do
      subject { create(:ci_runner, tag_list: ['tag']) }

      it { is_expected.to have_tags }
    end

    context 'when runner does not have tags' do
      subject { create(:ci_runner, tag_list: []) }

      it { is_expected.not_to have_tags }
    end
  end

  describe '.search' do
    let(:runner) { create(:ci_runner, token: '123abc', description: 'test runner') }

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

  describe '#assigned_to_group?' do
    subject { runner.assigned_to_group? }

    context 'when project runner' do
      let(:runner) { create(:ci_runner, :project, description: 'Project runner', projects: [project]) }
      let(:project) { create(:project) }

      it { is_expected.to be_falsey }
    end

    context 'when shared runner' do
      let(:runner) { create(:ci_runner, :instance, description: 'Shared runner') }

      it { is_expected.to be_falsey }
    end

    context 'when group runner' do
      let(:group) { create(:group) }
      let(:runner) { create(:ci_runner, :group, description: 'Group runner', groups: [group]) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#assigned_to_project?' do
    subject { runner.assigned_to_project? }

    context 'when group runner' do
      let(:runner) { create(:ci_runner, :group, description: 'Group runner', groups: [group]) }
      let(:group) { create(:group) }

      it { is_expected.to be_falsey }
    end

    context 'when shared runner' do
      let(:runner) { create(:ci_runner, :instance, description: 'Shared runner') }

      it { is_expected.to be_falsey }
    end

    context 'when project runner' do
      let(:runner) { create(:ci_runner, :project, description: 'Project runner', projects: [project]) }
      let(:project) { create(:project) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#pick_build!' do
    let(:build) { create(:ci_build) }
    let(:runner) { create(:ci_runner) }

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

    context 'build picking improvement' do
      it 'does not check if the build is assignable to a runner' do
        expect(runner).not_to receive(:can_pick?)

        runner.pick_build!(build)
      end
    end
  end

  describe 'project runner without projects is destroyable' do
    subject { create(:ci_runner, :project, :without_projects) }

    it 'does not have projects' do
      expect(subject.runner_projects).to be_empty
    end

    it 'can be destroyed' do
      subject
      expect { subject.destroy! }.to change { described_class.count }.by(-1)
    end
  end

  describe '.order_by' do
    it 'supports ordering by the contact date' do
      runner1 = create(:ci_runner, contacted_at: 1.year.ago)
      runner2 = create(:ci_runner, contacted_at: 1.month.ago)
      runners = described_class.order_by('contacted_asc')

      expect(runners).to eq([runner1, runner2])
    end

    it 'supports ordering by the creation date' do
      runner1 = create(:ci_runner, created_at: 1.year.ago)
      runner2 = create(:ci_runner, created_at: 1.month.ago)
      runners = described_class.order_by('created_asc')

      expect(runners).to eq([runner2, runner1])
    end
  end

  describe '.runner_matchers' do
    subject(:matchers) { described_class.all.runner_matchers }

    context 'deduplicates on runner_type' do
      before do
        create_list(:ci_runner, 2, :instance)
        create_list(:ci_runner, 2, :project)
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

    context 'with runner_ids' do
      before do
        create_list(:ci_runner, 2)
      end

      it 'includes runner_ids' do
        expect(matchers.size).to eq(1)

        expect(matchers.first.runner_ids).to match_array(described_class.all.pluck(:id))
      end
    end
  end

  describe '#runner_matcher' do
    let(:runner) do
      build_stubbed(:ci_runner, :instance_type, tag_list: %w[tag1 tag2])
    end

    subject(:matcher) { runner.runner_matcher }

    it { expect(matcher.runner_ids).to eq([runner.id]) }

    it { expect(matcher.runner_type).to eq(runner.runner_type) }

    it { expect(matcher.public_projects_minutes_cost_factor).to eq(runner.public_projects_minutes_cost_factor) }

    it { expect(matcher.private_projects_minutes_cost_factor).to eq(runner.private_projects_minutes_cost_factor) }

    it { expect(matcher.run_untagged).to eq(runner.run_untagged) }

    it { expect(matcher.access_level).to eq(runner.access_level) }

    it { expect(matcher.tag_list).to match_array(runner.tag_list) }
  end

  describe '#uncached_contacted_at' do
    let(:contacted_at_stored) { 1.hour.ago.change(usec: 0) }
    let(:runner) { create(:ci_runner, contacted_at: contacted_at_stored) }

    subject { runner.uncached_contacted_at }

    it { is_expected.to eq(contacted_at_stored) }
  end

  describe '.belonging_to_group' do
    it 'returns the specific group runner' do
      group = create(:group)
      runner = create(:ci_runner, :group, groups: [group])
      unrelated_group = create(:group)
      create(:ci_runner, :group, groups: [unrelated_group])

      expect(described_class.belonging_to_group(group.id)).to contain_exactly(runner)
    end

    context 'runner belonging to parent group' do
      let_it_be(:parent_group) { create(:group) }
      let_it_be(:parent_runner) { create(:ci_runner, :group, groups: [parent_group]) }
      let_it_be(:group) { create(:group, parent: parent_group) }

      context 'when include_parent option is passed' do
        it 'returns the group runner from the parent group' do
          expect(described_class.belonging_to_group(group.id, include_ancestors: true)).to contain_exactly(parent_runner)
        end
      end

      context 'when include_parent option is not passed' do
        it 'does not return the group runner from the parent group' do
          expect(described_class.belonging_to_group(group.id)).to be_empty
        end
      end
    end
  end
end
