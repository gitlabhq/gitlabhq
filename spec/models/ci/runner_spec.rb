require 'spec_helper'

describe Ci::Runner do
  describe 'validation' do
    it { is_expected.to validate_presence_of(:access_level) }

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

  describe '#display_name' do
    it 'returns the description if it has a value' do
      runner = FactoryBot.build(:ci_runner, description: 'Linux/Ruby-1.9.3-p448')
      expect(runner.display_name).to eq 'Linux/Ruby-1.9.3-p448'
    end

    it 'returns the token if it does not have a description' do
      runner = FactoryBot.create(:ci_runner)
      expect(runner.display_name).to eq runner.description
    end

    it 'returns the token if the description is an empty string' do
      runner = FactoryBot.build(:ci_runner, description: '', token: 'token')
      expect(runner.display_name).to eq runner.token
    end
  end

  describe '#assign_to' do
    let!(:project) { FactoryBot.create :project }
    let!(:shared_runner) { FactoryBot.create(:ci_runner, :shared) }

    before do
      shared_runner.assign_to(project)
    end

    it { expect(shared_runner).to be_specific }
    it { expect(shared_runner.projects).to eq([project]) }
    it { expect(shared_runner.only_for?(project)).to be_truthy }
  end

  describe '.online' do
    subject { described_class.online }

    before do
      @runner1 = FactoryBot.create(:ci_runner, :shared, contacted_at: 1.year.ago)
      @runner2 = FactoryBot.create(:ci_runner, :shared, contacted_at: 1.second.ago)
    end

    it { is_expected.to eq([@runner2])}
  end

  describe '#online?' do
    let(:runner) { FactoryBot.create(:ci_runner, :shared) }

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
      Gitlab::Redis::SharedState.with do |redis|
        cache_key = runner.send(:cache_attribute_key)
        expect(redis).to receive(:get).with(cache_key)
          .and_return({ contacted_at: value }.to_json).at_least(:once)
      end
    end
  end

  describe '#can_pick?' do
    let(:pipeline) { create(:ci_pipeline) }
    let(:build) { create(:ci_build, pipeline: pipeline) }
    let(:runner) { create(:ci_runner) }

    subject { runner.can_pick?(build) }

    before do
      build.project.runners << runner
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
      before do
        runner.tag_list = %w(bb cc)
      end

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
        before do
          runner.run_untagged = false
        end

        it 'cannot handle builds without tags' do
          expect(runner.can_pick?(build)).to be_falsey
        end

        it_behaves_like 'tagged build picker'
      end
    end

    context 'when runner is shared' do
      before do
        runner.is_shared = true
        build.project.runners = []
      end

      it 'can handle builds' do
        expect(runner.can_pick?(build)).to be_truthy
      end

      context 'when runner is locked' do
        before do
          runner.locked = true
        end

        it 'can handle builds' do
          expect(runner.can_pick?(build)).to be_truthy
        end
      end
    end

    context 'when runner is not shared' do
      context 'when runner is assigned to a project' do
        it 'can handle builds' do
          expect(runner.can_pick?(build)).to be_truthy
        end
      end

      context 'when runner is not assigned to a project' do
        before do
          build.project.runners = []
        end

        it 'cannot handle builds' do
          expect(runner.can_pick?(build)).to be_falsey
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
  end

  describe '#status' do
    let(:runner) { FactoryBot.create(:ci_runner, :shared, contacted_at: 1.second.ago) }

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

      expect_value_in_queues.to eq(last_update)
    end

    it 'does not change if it is not expired and called again' do
      last_update = runner.ensure_runner_queue_value

      expect(runner.ensure_runner_queue_value).to eq(last_update)
      expect_value_in_queues.to eq(last_update)
    end

    context 'updates runner queue after changing editable value' do
      let!(:last_update) { runner.ensure_runner_queue_value }

      before do
        Ci::UpdateRunnerService.new(runner).update(description: 'new runner')
      end

      it 'sets a new last_update value' do
        expect_value_in_queues.not_to eq(last_update)
      end
    end

    context 'does not update runner value after save' do
      let!(:last_update) { runner.ensure_runner_queue_value }

      before do
        runner.touch
      end

      it 'has an old last_update value' do
        expect_value_in_queues.to eq(last_update)
      end
    end

    def expect_value_in_queues
      Gitlab::Redis::Queues.with do |redis|
        runner_queue_key = runner.send(:runner_queue_key)
        expect(redis.get(runner_queue_key))
      end
    end
  end

  describe '#update_cached_info' do
    let(:runner) { create(:ci_runner) }

    subject { runner.update_cached_info(architecture: '18-bit') }

    context 'when database was updated recently' do
      before do
        runner.contacted_at = Time.now
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

      it 'updates database' do
        expect_redis_update

        expect { subject }.to change { runner.reload.read_attribute(:contacted_at) }
          .and change { runner.reload.read_attribute(:architecture) }
      end

      it 'updates cache' do
        expect_redis_update

        subject
      end
    end

    def expect_redis_update
      Gitlab::Redis::SharedState.with do |redis|
        redis_key = runner.send(:cache_attribute_key)
        expect(redis).to receive(:set).with(redis_key, anything, any_args)
      end
    end
  end

  describe '#destroy' do
    let(:runner) { create(:ci_runner) }

    context 'when there is a tick in the queue' do
      let!(:queue_key) { runner.send(:runner_queue_key) }

      before do
        runner.tick_runner_queue
        runner.destroy
      end

      it 'cleans up the queue' do
        Gitlab::Redis::Queues.with do |redis|
          expect(redis.get(queue_key)).to be_nil
        end
      end
    end
  end

  describe '.assignable_for' do
    let(:runner) { create(:ci_runner) }
    let(:project) { create(:project) }
    let(:another_project) { create(:project) }

    before do
      project.runners << runner
    end

    context 'with shared runners' do
      before do
        runner.update(is_shared: true)
      end

      context 'does not give owned runner' do
        subject { described_class.assignable_for(project) }

        it { is_expected.to be_empty }
      end

      context 'does not give shared runner' do
        subject { described_class.assignable_for(another_project) }

        it { is_expected.to be_empty }
      end
    end

    context 'with unlocked runner' do
      context 'does not give owned runner' do
        subject { described_class.assignable_for(project) }

        it { is_expected.to be_empty }
      end

      context 'does give a specific runner' do
        subject { described_class.assignable_for(another_project) }

        it { is_expected.to contain_exactly(runner) }
      end
    end

    context 'with locked runner' do
      before do
        runner.update(locked: true)
      end

      context 'does not give owned runner' do
        subject { described_class.assignable_for(project) }

        it { is_expected.to be_empty }
      end

      context 'does not give a locked runner' do
        subject { described_class.assignable_for(another_project) }

        it { is_expected.to be_empty }
      end
    end
  end

  describe "belongs_to_one_project?" do
    it "returns false if there are two projects runner assigned to" do
      runner = FactoryBot.create(:ci_runner)
      project = FactoryBot.create(:project)
      project1 = FactoryBot.create(:project)
      project.runners << runner
      project1.runners << runner

      expect(runner.belongs_to_one_project?).to be_falsey
    end

    it "returns true" do
      runner = FactoryBot.create(:ci_runner)
      project = FactoryBot.create(:project)
      project.runners << runner

      expect(runner.belongs_to_one_project?).to be_truthy
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

  describe '#defines_maximum_job_timeout?' do
    context 'when maximum job timeout is specified' do
      subject { create(:ci_runner, maximum_job_timeout: 1234) }

      it 'should return true' do
        expect(subject.defines_maximum_job_timeout?).to be_truthy
      end
    end

    context 'when maximum job timeout is not specified' do
      subject { create(:ci_runner) }

      it 'should return false' do
        expect(subject.defines_maximum_job_timeout?).to be_falsey
      end
    end
  end

  describe '.search' do
    let(:runner) { create(:ci_runner, token: '123abc', description: 'test runner') }

    it 'returns runners with a matching token' do
      expect(described_class.search(runner.token)).to eq([runner])
    end

    it 'returns runners with a partially matching token' do
      expect(described_class.search(runner.token[0..2])).to eq([runner])
    end

    it 'returns runners with a matching token regardless of the casing' do
      expect(described_class.search(runner.token.upcase)).to eq([runner])
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
end
