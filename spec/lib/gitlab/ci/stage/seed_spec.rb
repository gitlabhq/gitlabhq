require 'spec_helper'

describe Gitlab::Ci::Stage::Seed do
  let(:pipeline) { create(:ci_empty_pipeline) }

  let(:builds) do
    [{ name: 'rspec' }, { name: 'spinach' }]
  end

  subject do
    described_class.new(pipeline, 'test', builds)
  end

  describe '#stage' do
    it 'returns hash attributes of a stage' do
      expect(subject.stage).to be_a Hash
      expect(subject.stage).to include(:name, :project)
    end
  end

  describe '#builds' do
    it 'returns hash attributes of all builds' do
      expect(subject.builds.size).to eq 2
      expect(subject.builds).to all(include(ref: 'master'))
      expect(subject.builds).to all(include(tag: false))
      expect(subject.builds).to all(include(project: pipeline.project))
      expect(subject.builds)
        .to all(include(trigger_request: pipeline.trigger_requests.first))
    end
  end

  describe '#user=' do
    let(:user) { build(:user) }

    it 'assignes relevant pipeline attributes' do
      subject.user = user

      expect(subject.builds).to all(include(user: user))
    end
  end

  describe '#create!' do
    it 'creates all stages and builds' do
      subject.create!

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
  end
end
