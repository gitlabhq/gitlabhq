# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Group do
  let_it_be(:project) { create(:project) }

  let!(:jobs) { build_list(:ci_build, 1, :success, project: project) }

  subject do
    described_class.new(project, 'test', name: 'rspec', jobs: jobs)
  end

  it { is_expected.to include_module(StaticModel) }

  it { is_expected.to respond_to(:stage) }
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:jobs) }
  it { is_expected.to respond_to(:status) }

  describe '#size' do
    it 'returns the number of statuses in the group' do
      expect(subject.size).to eq(1)
    end
  end

  describe '#status' do
    let(:jobs) do
      [create(:ci_build, :failed)]
    end

    it 'returns a failed status' do
      expect(subject.status).to eq('failed')
    end
  end

  describe '#detailed_status' do
    context 'when there is only one item in the group' do
      it 'calls the status from the object itself' do
        expect(jobs.first).to receive(:detailed_status)

        subject.detailed_status(double(:user))
      end
    end

    context 'when there are more than one commit status in the group' do
      let(:jobs) do
        [create(:ci_build, :failed),
         create(:ci_build, :success)]
      end

      it 'fabricates a new detailed status object' do
        expect(subject.detailed_status(double(:user)))
          .to be_a(Gitlab::Ci::Status::Failed)
      end
    end

    context 'when one of the commit statuses in the group is allowed to fail' do
      let(:jobs) do
        [create(:ci_build, :failed, :allowed_to_fail),
         create(:ci_build, :success)]
      end

      it 'fabricates a new detailed status object' do
        expect(subject.detailed_status(double(:user)))
          .to be_a(Gitlab::Ci::Status::SuccessWarning)
      end
    end
  end

  describe '.fabricate' do
    let(:pipeline) { create(:ci_empty_pipeline) }
    let(:stage) { create(:ci_stage, pipeline: pipeline) }

    before do
      create_build(:ci_build, name: 'rspec 0 2')
      create_build(:ci_build, name: 'rspec 0 1')
      create_build(:ci_build, name: 'spinach 0 1')
      create_build(:commit_status, name: 'aaaaa')
    end

    it 'returns an array of three groups' do
      expect(stage.groups).to be_a Array
      expect(stage.groups).to all(be_a described_class)
      expect(stage.groups.size).to eq 3
    end

    it 'returns groups with correctly ordered statuses' do
      expect(stage.groups.first.jobs.map(&:name))
        .to eq ['aaaaa']
      expect(stage.groups.second.jobs.map(&:name))
        .to eq ['rspec 0 1', 'rspec 0 2']
      expect(stage.groups.third.jobs.map(&:name))
        .to eq ['spinach 0 1']
    end

    it 'returns groups with correct names' do
      expect(stage.groups.map(&:name))
        .to eq %w[aaaaa rspec spinach]
    end

    context 'when a name is nil on legacy pipelines' do
      before do
        pipeline.builds.first.update_attribute(:name, nil)
      end

      it 'returns an array of three groups' do
        expect(stage.groups.map(&:name))
          .to eq ['', 'aaaaa', 'rspec', 'spinach']
      end
    end

    def create_build(type, status: 'success', **opts)
      create(
        type, pipeline: pipeline,
        stage: stage.name,
        status: status,
        stage_id: stage.id,
        **opts
      )
    end
  end
end
