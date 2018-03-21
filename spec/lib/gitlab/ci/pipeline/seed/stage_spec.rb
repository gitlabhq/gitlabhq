require 'spec_helper'

describe Gitlab::Ci::Pipeline::Seed::Stage do
  let(:pipeline) { create(:ci_empty_pipeline) }

  let(:builds) do
    [{ name: 'rspec' }, { name: 'spinach' }]
  end

  subject do
    described_class.new(pipeline, 'test', builds)
  end

  describe '#size' do
    it 'returns a number of jobs in the stage' do
      expect(subject.size).to eq 2
    end
  end

  describe '#attributes' do
    it 'returns hash attributes of a stage' do
      expect(subject.attributes).to be_a Hash
      expect(subject.attributes).to include(:name, :project)
    end
  end

  describe '#seeds' do
    it 'returns hash attributes of all builds' do
      expect(subject.seeds.size).to eq 2
      expect(subject.seeds.map(&:attributes)).to all(include(ref: 'master'))
      expect(subject.seeds.map(&:attributes)).to all(include(tag: false))
      expect(subject.seeds.map(&:attributes)).to all(include(project: pipeline.project))
      expect(subject.seeds.map(&:attributes))
        .to all(include(trigger_request: pipeline.trigger_requests.first))
    end

    context 'when a ref is protected' do
      before do
        allow_any_instance_of(Project).to receive(:protected_for?).and_return(true)
      end

      it 'returns protected builds' do
        expect(subject.seeds.map(&:attributes)).to all(include(protected: true))
      end
    end

    context 'when a ref is not protected' do
      before do
        allow_any_instance_of(Project).to receive(:protected_for?).and_return(false)
      end

      it 'returns unprotected builds' do
        expect(subject.seeds.map(&:attributes)).to all(include(protected: false))
      end
    end
  end

  describe '#user=' do
    let(:user) { build(:user) }

    it 'assignes relevant pipeline attributes' do
      subject.user = user

      expect(subject.seeds.map(&:attributes)).to all(include(user: user))
    end
  end

  describe '#to_resource' do
    it 'builds a valid stage object with all builds' do
      subject.to_resource.save!

      expect(pipeline.reload.stages.count).to eq 1
      expect(pipeline.reload.builds.count).to eq 2
      expect(pipeline.builds).to all(satisfy { |job| job.stage_id.present? })
      expect(pipeline.builds).to all(satisfy { |job| job.pipeline.present? })
      expect(pipeline.builds).to all(satisfy { |job| job.project.present? })
      expect(pipeline.stages)
        .to all(satisfy { |stage| stage.pipeline.present? })
      expect(pipeline.stages)
        .to all(satisfy { |stage| stage.project.present? })
    end

    it 'can not be persisted without explicit pipeline assignment' do
      stage = subject.to_resource

      pipeline.save!

      expect(stage).not_to be_persisted
      expect(pipeline.reload.stages.count).to eq 0
      expect(pipeline.reload.builds.count).to eq 0
    end
  end
end
