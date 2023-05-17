# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runner, type: :model, feature_category: :runner do
  include StubGitlabCalls

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
      runner = create(:ci_runner, :group)

      with_cross_joins_prevented do
        expect(runner.groups.count).to eq(1)
      end
    end
  end

  describe 'projects association' do
    let(:runner) { create(:ci_runner, :project) }

    it 'does not create a cross-database query' do
      with_cross_joins_prevented do
        expect(runner.projects.count).to eq(1)
      end
    end
  end

  describe 'acts_as_taggable' do
    let(:tag_name) { 'tag123' }

    context 'on save' do
      let_it_be_with_reload(:runner) { create(:ci_runner) }

      before do
        runner.tag_list = [tag_name]
      end

      context 'tag does not exist' do
        it 'creates a tag' do
          expect { runner.save! }.to change(ActsAsTaggableOn::Tag, :count).by(1)
        end

        it 'creates an association to the tag' do
          runner.save!

          expect(described_class.tagged_with(tag_name)).to include(runner)
        end
      end

      context 'tag already exists' do
        before do
          ActsAsTaggableOn::Tag.create!(name: tag_name)
        end

        it 'does not create a tag' do
          expect { runner.save! }.not_to change(ActsAsTaggableOn::Tag, :count)
        end

        it 'creates an association to the tag' do
          runner.save!

          expect(described_class.tagged_with(tag_name)).to include(runner)
        end
      end
    end
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:access_level) }
    it { is_expected.to validate_presence_of(:runner_type) }
    it { is_expected.to validate_presence_of(:registration_type) }

    context 'when runner is not allowed to pick untagged jobs' do
      context 'when runner does not have tags' do
        let(:runner) { build(:ci_runner, tag_list: [], run_untagged: false) }

        it 'is not valid' do
          expect(runner).to be_invalid
        end
      end

      context 'when runner has too many tags' do
        let(:runner) { build(:ci_runner, tag_list: (1..::Ci::Runner::TAG_LIST_MAX_LENGTH + 1).map { |i| "tag#{i}" }, run_untagged: false) }

        it 'is not valid' do
          expect(runner).to be_invalid
        end
      end

      context 'when runner has tags' do
        let(:runner) { build(:ci_runner, tag_list: ['tag'], run_untagged: false) }

        it 'is valid' do
          expect(runner).to be_valid
        end
      end
    end

    describe '#exactly_one_group' do
      let(:group) { create(:group) }
      let(:runner) { create(:ci_runner, :group, groups: [group]) }

      it 'disallows assigning group if already assigned to a group' do
        runner.runner_namespaces << create(:ci_runner_namespace)

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
    it 'returns the project runner' do
      # own
      own_project = create(:project)
      own_runner = create(:ci_runner, :project, projects: [own_project])

      # other
      other_project = create(:project)
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

  context 'when use_traversal_ids* are enabled' do
    it_behaves_like '.belonging_to_parent_groups_of_project'
  end

  context 'when use_traversal_ids* are disabled' do
    before do
      stub_feature_flags(
        use_traversal_ids: false,
        use_traversal_ids_for_ancestors: false,
        use_traversal_ids_for_ancestor_scopes: false
      )
    end

    it_behaves_like '.belonging_to_parent_groups_of_project'
  end

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

  describe '#only_for' do
    let_it_be_with_reload(:runner) { create(:ci_runner, :project) }
    let_it_be(:project) { runner.projects.first }

    subject { runner.only_for?(project) }

    context 'with matching project' do
      it { is_expected.to be_truthy }
    end

    context 'without matching project' do
      let_it_be(:project) { create(:project) }

      it { is_expected.to be_falsey }
    end

    context 'with runner having multiple projects' do
      let_it_be(:other_project) { create(:project) }
      let_it_be(:runner_project) { create(:ci_runner_project, project: other_project, runner: runner) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#assign_to' do
    let(:project) { create(:project) }

    subject { runner.assign_to(project) }

    context 'with shared_runner' do
      let(:runner) { create(:ci_runner, :instance) }

      it 'raises an error' do
        expect { subject }
          .to raise_error(ArgumentError, 'Transitioning an instance runner to a project runner is not supported')
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

    context 'with project runner' do
      let(:other_project) { create(:project) }
      let(:runner) { create(:ci_runner, :project, projects: [other_project]) }

      it 'assigns runner to project' do
        expect(subject).to be_truthy

        expect(runner).to be_project_type
        expect(runner.runner_projects.pluck(:project_id)).to contain_exactly(project.id, other_project.id)
      end
    end
  end

  describe '.recent' do
    subject { described_class.recent }

    let!(:runner1) { create(:ci_runner, :instance, contacted_at: nil, created_at: 2.months.ago) }
    let!(:runner2) { create(:ci_runner, :instance, contacted_at: nil, created_at: 3.months.ago) }
    let!(:runner3) { create(:ci_runner, :instance, contacted_at: 1.month.ago, created_at: 2.months.ago) }
    let!(:runner4) { create(:ci_runner, :instance, contacted_at: 1.month.ago, created_at: 3.months.ago) }

    it { is_expected.to eq([runner1, runner3, runner4]) }
  end

  describe '.active' do
    subject { described_class.active(active_value) }

    let_it_be(:runner1) { create(:ci_runner, :instance, active: false) }
    let_it_be(:runner2) { create(:ci_runner, :instance) }

    context 'with active_value set to false' do
      let(:active_value) { false }

      it 'returns inactive runners' do
        is_expected.to match_array([runner1])
      end
    end

    context 'with active_value set to true' do
      let(:active_value) { true }

      it 'returns active runners' do
        is_expected.to match_array([runner2])
      end
    end
  end

  describe '.paused' do
    before do
      expect(described_class).to receive(:active).with(false).and_call_original
    end

    subject { described_class.paused }

    let!(:runner1) { create(:ci_runner, :instance, active: false) }
    let!(:runner2) { create(:ci_runner, :instance) }

    it 'returns inactive runners' do
      is_expected.to match_array([runner1])
    end
  end

  describe '.stale', :freeze_time do
    subject { described_class.stale }

    let!(:runner1) { create(:ci_runner, :instance, created_at: 4.months.ago, contacted_at: 3.months.ago + 1.second) }
    let!(:runner2) { create(:ci_runner, :instance, created_at: 4.months.ago, contacted_at: 3.months.ago) }
    let!(:runner3) { create(:ci_runner, :instance, created_at: 3.months.ago, contacted_at: nil) }
    let!(:runner4) { create(:ci_runner, :instance, created_at: 2.months.ago, contacted_at: nil) }

    it 'returns stale runners' do
      is_expected.to match_array([runner2, runner3])
    end
  end

  describe '#stale?', :clean_gitlab_redis_cache, :freeze_time do
    let(:runner) { build(:ci_runner, :instance) }

    subject { runner.stale? }

    before do
      allow_any_instance_of(described_class).to receive(:cached_attribute).and_call_original
      allow_any_instance_of(described_class).to receive(:cached_attribute)
        .with(:platform).and_return("darwin")
      allow_any_instance_of(described_class).to receive(:cached_attribute)
        .with(:version).and_return("14.0.0")

      allow(Ci::Runners::ProcessRunnerVersionUpdateWorker).to receive(:perform_async).once
    end

    context 'table tests' do
      using RSpec::Parameterized::TableSyntax

      where(:created_at, :contacted_at, :expected_stale?) do
        nil                     | nil                     | false
        3.months.ago            | 3.months.ago            | true
        3.months.ago            | (3.months - 1.hour).ago | false
        3.months.ago            | nil                     | true
        (3.months - 1.hour).ago | nil                     | false
      end

      with_them do
        before do
          runner.created_at = created_at
        end

        context 'no cache value' do
          before do
            stub_redis_runner_contacted_at(nil)
            runner.contacted_at = contacted_at
          end

          it { is_expected.to eq(expected_stale?) }
        end

        context 'with cache value' do
          before do
            runner.contacted_at = contacted_at ? contacted_at + 1.week : nil
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

  describe '.online', :freeze_time do
    subject { described_class.online }

    let!(:runner1) { create(:ci_runner, :instance, contacted_at: 2.hours.ago) }
    let!(:runner2) { create(:ci_runner, :instance, contacted_at: 1.second.ago) }

    it { is_expected.to match_array([runner2]) }
  end

  describe '#online?', :clean_gitlab_redis_cache, :freeze_time do
    let(:runner) { build(:ci_runner, :instance) }

    subject { runner.online? }

    before do
      allow_any_instance_of(described_class).to receive(:cached_attribute).and_call_original
      allow_any_instance_of(described_class).to receive(:cached_attribute)
        .with(:platform).and_return("darwin")
      allow_any_instance_of(described_class).to receive(:cached_attribute)
        .with(:version).and_return("14.0.0")

      allow(Ci::Runners::ProcessRunnerVersionUpdateWorker).to receive(:perform_async).once
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

      context 'contacted long time ago' do
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
      context 'contacted long time ago' do
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

    let!(:runner1) { create(:ci_runner, :instance, contacted_at: 2.hours.ago) }
    let!(:runner2) { create(:ci_runner, :instance, contacted_at: 1.second.ago) }

    it { is_expected.to eq([runner1]) }
  end

  describe '.with_running_builds' do
    subject { described_class.with_running_builds }

    let_it_be(:runner1) { create(:ci_runner) }

    context 'with no builds running' do
      it { is_expected.to be_empty }
    end

    context 'with single build running on runner2' do
      let(:runner2) { create(:ci_runner) }
      let(:runner3) { create(:ci_runner) }

      before do
        project = create(:project, :repository)
        pipeline = create(:ci_pipeline, project: project)
        create(:ci_build, :running, runner: runner2, pipeline: pipeline)
        create(:ci_build, :running, runner: runner3, pipeline: pipeline)
      end

      it { is_expected.to contain_exactly(runner2, runner3) }
    end
  end

  describe '#matches_build?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:pipeline) { create(:ci_pipeline) }

    let(:build) { create(:ci_build, pipeline: pipeline) }
    let(:runner_project) { build.project }
    let(:runner) { create(:ci_runner, :project, projects: [runner_project], tag_list: tag_list, run_untagged: run_untagged) }
    let(:tag_list) { [] }
    let(:run_untagged) { true }

    subject { runner.matches_build?(build) }

    context 'when runner does not have tags' do
      it { is_expected.to be_truthy }

      it 'cannot handle build with tags' do
        build.tag_list = ['aa']

        is_expected.to be_falsey
      end
    end

    context 'when runner has tags' do
      let(:tag_list) { %w(bb cc) }

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
    let(:runner) { build(:ci_runner, :instance, created_at: 3.months.ago) }

    subject { runner.status }

    context 'never connected' do
      before do
        runner.contacted_at = nil
      end

      it { is_expected.to eq(:stale) }

      context 'created recently' do
        before do
          runner.created_at = 1.day.ago
        end

        it { is_expected.to eq(:never_contacted) }
      end
    end

    context 'inactive but online' do
      before do
        runner.contacted_at = 1.second.ago
        runner.active = false
      end

      it { is_expected.to eq(:online) }
    end

    context 'contacted 1s ago' do
      before do
        runner.contacted_at = 1.second.ago
      end

      it { is_expected.to eq(:online) }
    end

    context 'contacted recently' do
      before do
        runner.contacted_at = (3.months - 1.second).ago
      end

      it { is_expected.to eq(:offline) }
    end

    context 'contacted long time ago' do
      before do
        runner.contacted_at = 3.months.ago
      end

      it { is_expected.to eq(:stale) }
    end
  end

  describe '#deprecated_rest_status', :freeze_time do
    let(:runner) { create(:ci_runner, :instance, contacted_at: 1.second.ago) }

    subject { runner.deprecated_rest_status }

    context 'never connected' do
      before do
        runner.contacted_at = nil
      end

      it { is_expected.to eq(:never_contacted) }
    end

    context 'contacted 1s ago' do
      before do
        runner.contacted_at = 1.second.ago
      end

      it { is_expected.to eq(:online) }
    end

    context 'contacted long time ago' do
      before do
        runner.created_at = 3.months.ago
        runner.contacted_at = 3.months.ago
      end

      it { is_expected.to eq(:stale) }
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
        Ci::Runners::UpdateRunnerService.new(runner).execute(description: 'new runner')
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

  describe '#heartbeat', :freeze_time do
    let(:runner) { create(:ci_runner, :project, version: '15.0.0') }
    let(:executor) { 'shell' }
    let(:values) { { architecture: '18-bit', config: { gpus: "all" }, executor: executor, version: version } }

    subject(:heartbeat) do
      runner.heartbeat(values)
    end

    context 'when database was updated recently' do
      before do
        runner.contacted_at = Time.current
      end

      context 'when version is changed' do
        let(:version) { '15.0.1' }

        before do
          allow(Ci::Runners::ProcessRunnerVersionUpdateWorker).to receive(:perform_async).with(version)
        end

        it 'updates cache' do
          expect_redis_update

          heartbeat

          expect(runner.runner_version).to be_nil
        end

        it 'schedules version information update' do
          heartbeat

          expect(Ci::Runners::ProcessRunnerVersionUpdateWorker).to have_received(:perform_async).with(version).once
        end

        context 'when fetching runner releases is disabled' do
          before do
            stub_application_setting(update_runner_versions_enabled: false)
          end

          it 'does not schedule version information update' do
            heartbeat

            expect(Ci::Runners::ProcessRunnerVersionUpdateWorker).not_to have_received(:perform_async)
          end
        end
      end

      context 'with only ip_address specified', :freeze_time do
        let(:values) do
          { ip_address: '1.1.1.1' }
        end

        it 'updates only ip_address' do
          expect_redis_update(values.merge(contacted_at: Time.current))

          heartbeat
        end

        context 'with new version having been cached' do
          let(:version) { '15.0.1' }

          before do
            runner.cache_attributes(version: version)
          end

          it 'does not lose cached version value' do
            expect { heartbeat }.not_to change { runner.version }.from(version)
          end
        end
      end
    end

    context 'when database was not updated recently' do
      before do
        runner.contacted_at = 2.hours.ago

        allow(Ci::Runners::ProcessRunnerVersionUpdateWorker).to receive(:perform_async).with(version)
      end

      context 'when version is changed' do
        let(:version) { '15.0.1' }

        context 'with invalid runner' do
          before do
            runner.runner_projects.delete_all
          end

          it 'still updates redis cache and database' do
            expect(runner).to be_invalid

            expect_redis_update
            does_db_update

            expect(Ci::Runners::ProcessRunnerVersionUpdateWorker).to have_received(:perform_async).with(version).once
          end
        end

        it 'updates redis cache and database' do
          expect_redis_update
          does_db_update
          expect(Ci::Runners::ProcessRunnerVersionUpdateWorker).to have_received(:perform_async).with(version).once
        end
      end

      context 'with unchanged runner version' do
        let(:version) { runner.version }

        it 'does not schedule ci_runner_versions update' do
          heartbeat

          expect(Ci::Runners::ProcessRunnerVersionUpdateWorker).not_to have_received(:perform_async)
        end

        Ci::Runner::EXECUTOR_NAME_TO_TYPES.each_key do |executor|
          context "with #{executor} executor" do
            let(:executor) { executor }

            it 'updates with expected executor type' do
              expect_redis_update

              heartbeat

              expect(runner.reload.read_attribute(:executor_type)).to eq(expected_executor_type)
            end

            def expected_executor_type
              executor.gsub(/[+-]/, '_')
            end
          end
        end

        context 'with an unknown executor type' do
          let(:executor) { 'some-unknown-type' }

          it 'updates with unknown executor type' do
            expect_redis_update

            heartbeat

            expect(runner.reload.read_attribute(:executor_type)).to eq('unknown')
          end
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
        .and change { runner.reload.read_attribute(:architecture) }
        .and change { runner.reload.read_attribute(:config) }
        .and change { runner.reload.read_attribute(:executor_type) }
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
    let_it_be(:project1) { create(:project) }
    let_it_be(:project2) { create(:project) }

    describe '#owner_project' do
      subject(:owner_project) { project_runner.owner_project }

      context 'with project1 as first project associated with runner' do
        let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project1, project2]) }

        it { is_expected.to eq project1 }
      end

      context 'with project2 as first project associated with runner' do
        let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project2, project1]) }

        it { is_expected.to eq project2 }
      end
    end

    describe '#belongs_to_one_project?' do
      it "returns false if there are two projects runner is assigned to" do
        runner = create(:ci_runner, :project, projects: [project1, project2])

        expect(runner.belongs_to_one_project?).to be_falsey
      end

      it 'returns true if there is only one project runner is assigned to' do
        runner = create(:ci_runner, :project, projects: [project1])

        expect(runner.belongs_to_one_project?).to be_truthy
      end
    end

    describe '#belongs_to_more_than_one_project?' do
      context 'project runner' do
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
  end

  describe '#save_tags' do
    let(:runner) { build(:ci_runner, tag_list: ['tag']) }

    it 'saves tags' do
      runner.save!

      expect(runner.tags.count).to eq(1)
      expect(runner.tags.first.name).to eq('tag')
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
      subject { create(:ci_runner, tag_list: ['tag']) }

      it { is_expected.to have_tags }
    end

    context 'when runner does not have tags' do
      subject { create(:ci_runner, tag_list: []) }

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

    let(:build) { create(:ci_build) }

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
  end

  describe '#short_sha' do
    subject(:short_sha) { runner.short_sha }

    context 'when registered via command-line' do
      let(:runner) { create(:ci_runner) }

      specify { expect(runner.token).not_to start_with(described_class::CREATED_RUNNER_TOKEN_PREFIX) }
      it { is_expected.not_to start_with(described_class::CREATED_RUNNER_TOKEN_PREFIX) }
    end

    context 'when creating new runner via UI' do
      let(:runner) { create(:ci_runner, registration_type: :authenticated_user) }

      specify { expect(runner.token).to start_with(described_class::CREATED_RUNNER_TOKEN_PREFIX) }
      it { is_expected.not_to start_with(described_class::CREATED_RUNNER_TOKEN_PREFIX) }
    end
  end

  describe '#token' do
    subject(:token) { runner.token }

    context 'when runner is registered' do
      let(:runner) { create(:ci_runner) }

      it { is_expected.not_to start_with('glrt-') }
    end

    context 'when runner is created via UI' do
      let(:runner) { create(:ci_runner, registration_type: :authenticated_user) }

      it { is_expected.to start_with('glrt-') }
    end
  end

  describe '#token_expires_at', :freeze_time do
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
      let(:runner) { create(:ci_runner) }

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

      let(:runner) { create(:ci_runner) }

      it_behaves_like 'non-expiring token'
    end

    context 'system-wide project expiration' do
      before do
        stub_application_setting(project_runner_token_expiration_interval: 5.days.to_i)
      end

      let(:runner) { create(:ci_runner) }

      it_behaves_like 'non-expiring token'
    end

    context 'group expiration' do
      let(:group_settings) { create(:namespace_settings, runner_token_expiration_interval: 6.days.to_i) }
      let(:group) { create(:group, namespace_settings: group_settings) }
      let(:runner) { create(:ci_runner, :group, groups: [group]) }

      it_behaves_like 'expiring token', interval: 6.days
    end

    context 'human-readable group expiration' do
      let(:group_settings) { create(:namespace_settings, runner_token_expiration_interval_human_readable: '7 days') }
      let(:group) { create(:group, namespace_settings: group_settings) }
      let(:runner) { create(:ci_runner, :group, groups: [group]) }

      it_behaves_like 'expiring token', interval: 7.days
    end

    context 'project expiration' do
      let(:project) { create(:project, runner_token_expiration_interval: 4.days.to_i).tap(&:save!) }
      let(:runner) { create(:ci_runner, :project, projects: [project]) }

      it_behaves_like 'expiring token', interval: 4.days
    end

    context 'human-readable project expiration' do
      let(:project) { create(:project, runner_token_expiration_interval_human_readable: '5 days').tap(&:save!) }
      let(:runner) { create(:ci_runner, :project, projects: [project]) }

      it_behaves_like 'expiring token', interval: 5.days
    end

    context 'multiple projects' do
      let(:project1) { create(:project, runner_token_expiration_interval: 8.days.to_i).tap(&:save!) }
      let(:project2) { create(:project, runner_token_expiration_interval: 7.days.to_i).tap(&:save!) }
      let(:project3) { create(:project, runner_token_expiration_interval: 9.days.to_i).tap(&:save!) }
      let(:runner) { create(:ci_runner, :project, projects: [project1, project2, project3]) }

      it_behaves_like 'expiring token', interval: 7.days
    end

    context 'with project runner token expiring' do
      let_it_be(:project) { create(:project, runner_token_expiration_interval: 4.days.to_i).tap(&:save!) }

      context 'project overrides system' do
        before do
          stub_application_setting(project_runner_token_expiration_interval: 5.days.to_i)
        end

        let(:runner) { create(:ci_runner, :project, projects: [project]) }

        it_behaves_like 'expiring token', interval: 4.days
      end

      context 'system overrides project' do
        before do
          stub_application_setting(project_runner_token_expiration_interval: 3.days.to_i)
        end

        let(:runner) { create(:ci_runner, :project, projects: [project]) }

        it_behaves_like 'expiring token', interval: 3.days
      end
    end

    context 'with group runner token expiring' do
      let_it_be(:group_settings) { create(:namespace_settings, runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:group) { create(:group, namespace_settings: group_settings) }

      context 'group overrides system' do
        before do
          stub_application_setting(group_runner_token_expiration_interval: 5.days.to_i)
        end

        let(:runner) { create(:ci_runner, :group, groups: [group]) }

        it_behaves_like 'expiring token', interval: 4.days
      end

      context 'system overrides group' do
        before do
          stub_application_setting(group_runner_token_expiration_interval: 3.days.to_i)
        end

        let(:runner) { create(:ci_runner, :group, groups: [group]) }

        it_behaves_like 'expiring token', interval: 3.days
      end
    end

    context "with group's project runner token expiring" do
      let_it_be(:parent_group_settings) { create(:namespace_settings, subgroup_runner_token_expiration_interval: 2.days.to_i) }
      let_it_be(:parent_group) { create(:group, namespace_settings: parent_group_settings) }

      context 'parent group overrides subgroup' do
        let(:group_settings) { create(:namespace_settings, runner_token_expiration_interval: 3.days.to_i) }
        let(:group) { create(:group, parent: parent_group, namespace_settings: group_settings) }
        let(:runner) { create(:ci_runner, :group, groups: [group]) }

        it_behaves_like 'expiring token', interval: 2.days
      end

      context 'subgroup overrides parent group' do
        let(:group_settings) { create(:namespace_settings, runner_token_expiration_interval: 1.day.to_i) }
        let(:group) { create(:group, parent: parent_group, namespace_settings: group_settings) }
        let(:runner) { create(:ci_runner, :group, groups: [group]) }

        it_behaves_like 'expiring token', interval: 1.day
      end
    end

    context "with group's project runner token expiring" do
      let_it_be(:group_settings) { create(:namespace_settings, project_runner_token_expiration_interval: 2.days.to_i) }
      let_it_be(:group) { create(:group, namespace_settings: group_settings) }

      context 'group overrides project' do
        let(:project) { create(:project, group: group, runner_token_expiration_interval: 3.days.to_i).tap(&:save!) }
        let(:runner) { create(:ci_runner, :project, projects: [project]) }

        it_behaves_like 'expiring token', interval: 2.days
      end

      context 'project overrides group' do
        let(:project) { create(:project, group: group, runner_token_expiration_interval: 1.day.to_i).tap(&:save!) }
        let(:runner) { create(:ci_runner, :project, projects: [project]) }

        it_behaves_like 'expiring token', interval: 1.day
      end
    end
  end

  describe '.with_upgrade_status' do
    subject { described_class.with_upgrade_status(upgrade_status) }

    let_it_be(:runner_14_0_0) { create(:ci_runner, version: '14.0.0') }
    let_it_be(:runner_14_1_0) { create(:ci_runner, version: '14.1.0') }
    let_it_be(:runner_14_1_1) { create(:ci_runner, version: '14.1.1') }
    let_it_be(:runner_version_14_0_0) { create(:ci_runner_version, version: '14.0.0', status: :available) }
    let_it_be(:runner_version_14_1_0) { create(:ci_runner_version, version: '14.1.0', status: :recommended) }
    let_it_be(:runner_version_14_1_1) { create(:ci_runner_version, version: '14.1.1', status: :unavailable) }

    context ':unavailable' do
      let(:upgrade_status) { :unavailable }

      it 'returns runners whose version is assigned :unavailable' do
        is_expected.to contain_exactly(runner_14_1_1)
      end
    end

    context ':available' do
      let(:upgrade_status) { :available }

      it 'returns runners whose version is assigned :available' do
        is_expected.to contain_exactly(runner_14_0_0)
      end
    end

    context ':recommended' do
      let(:upgrade_status) { :recommended }

      it 'returns runners whose version is assigned :recommended' do
        is_expected.to contain_exactly(runner_14_1_0)
      end
    end

    describe 'composed with other scopes' do
      subject { described_class.active(false).with_upgrade_status(:available) }

      let(:inactive_runner_14_0_0) { create(:ci_runner, version: '14.0.0', active: false) }

      it 'returns runner matching the composed scope' do
        is_expected.to contain_exactly(inactive_runner_14_0_0)
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
    let(:runner) { described_class.new(registration_type: registration_type) }
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
end
