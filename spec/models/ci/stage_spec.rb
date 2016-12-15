require 'spec_helper'

describe Ci::Stage, models: true do
  let(:stage) { build(:ci_stage) }
  let(:pipeline) { stage.pipeline }
  let(:stage_name) { stage.name }

  describe '#expectations' do
    subject { stage }

    it { is_expected.to include_module(StaticModel) }

    it { is_expected.to respond_to(:pipeline) }
    it { is_expected.to respond_to(:name) }

    it { is_expected.to delegate_method(:project).to(:pipeline) }
  end

  describe '#statuses' do
    let!(:stage_build) { create_job(:ci_build) }
    let!(:commit_status) { create_job(:commit_status) }
    let!(:other_build) { create_job(:ci_build, stage: 'other stage') }

    subject { stage.statuses }

    it "returns only matching statuses" do
      is_expected.to contain_exactly(stage_build, commit_status)
    end
  end

  describe '#builds' do
    let!(:stage_build) { create_job(:ci_build) }
    let!(:commit_status) { create_job(:commit_status) }

    subject { stage.builds }

    it "returns only builds" do
      is_expected.to contain_exactly(stage_build)
    end
  end

  describe '#status' do
    subject { stage.status }

    context 'if status is already defined' do
      let(:stage) { build(:ci_stage, status: 'success') }

      it "returns defined status" do
        is_expected.to eq('success')
      end
    end

    context 'if status has to be calculated' do
      let!(:stage_build) { create_job(:ci_build, status: :failed) }

      it "returns status of a build" do
        is_expected.to eq('failed')
      end

      context 'and builds are retried' do
        let!(:new_build) { create_job(:ci_build, status: :success) }

        it "returns status of latest build" do
          is_expected.to eq('success')
        end
      end
    end
  end

  describe '#detailed_status' do
    let(:user) { create(:user) }

    subject { stage.detailed_status(user) }

    context 'when build is created' do
      let!(:stage_build) { create_job(:ci_build, status: :created) }

      it 'returns detailed status for created stage' do
        expect(subject.text).to eq 'created'
      end
    end

    context 'when build is pending' do
      let!(:stage_build) { create_job(:ci_build, status: :pending) }

      it 'returns detailed status for pending stage' do
        expect(subject.text).to eq 'pending'
      end
    end

    context 'when build is running' do
      let!(:stage_build) { create_job(:ci_build, status: :running) }

      it 'returns detailed status for running stage' do
        expect(subject.text).to eq 'running'
      end
    end

    context 'when build is successful' do
      let!(:stage_build) { create_job(:ci_build, status: :success) }

      it 'returns detailed status for successful stage' do
        expect(subject.text).to eq 'passed'
      end
    end

    context 'when build is failed' do
      let!(:stage_build) { create_job(:ci_build, status: :failed) }

      it 'returns detailed status for failed stage' do
        expect(subject.text).to eq 'failed'
      end
    end

    context 'when build is canceled' do
      let!(:stage_build) { create_job(:ci_build, status: :canceled) }

      it 'returns detailed status for canceled stage' do
        expect(subject.text).to eq 'canceled'
      end
    end

    context 'when build is skipped' do
      let!(:stage_build) { create_job(:ci_build, status: :skipped) }

      it 'returns detailed status for skipped stage' do
        expect(subject.text).to eq 'skipped'
      end
    end
  end

  def create_job(type, status: 'success', stage: stage_name)
    create(type, pipeline: pipeline, stage: stage, status: status)
  end
end
