require 'spec_helper'

describe Gitlab::Ci::Stage::Seed do
  subject do
    described_class.new(name: 'test', builds: builds)
  end

  let(:builds) do
    [{ name: 'rspec' }, { name: 'spinach' }]
  end

  describe '#pipeline=' do
    let(:pipeline) do
      create(:ci_empty_pipeline, ref: 'feature', tag: true)
    end

    it 'assignes relevant pipeline attributes' do
      trigger_request = pipeline.trigger_requests.first

      subject.pipeline = pipeline

      expect(subject.builds).to all(include(pipeline: pipeline))
      expect(subject.builds).to all(include(project: pipeline.project))
      expect(subject.builds).to all(include(ref: 'feature'))
      expect(subject.builds).to all(include(tag: true))
      expect(subject.builds).to all(include(trigger_request: trigger_request))
    end
  end

  describe '#user=' do
    let(:user) { create(:user) }

    it 'assignes relevant pipeline attributes' do
      subject.user = user

      expect(subject.builds).to all(include(user: user))
    end
  end

  describe '#to_attributes' do
    it 'exposes stage attributes with nested jobs' do
      expect(subject.to_attributes).to be_a Hash
      expect(subject.to_attributes).to include(name: 'test')
      expect(subject.to_attributes).to include(builds_attributes: builds)
    end
  end
end
