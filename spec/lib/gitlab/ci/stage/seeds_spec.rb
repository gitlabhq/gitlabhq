require 'spec_helper'

describe Gitlab::Ci::Stage::Seeds do
  before do
    subject.append_stage('test', [{ name: 'rspec' }, { name: 'spinach' }])
    subject.append_stage('deploy', [{ name: 'prod', script: 'cap deploy' }])
  end

  describe '#stages' do
    it 'returns hashes of all stages' do
      expect(subject.stages.size).to eq 2
      expect(subject.stages).to all(be_a Hash)
    end
  end

  describe '#jobs' do
    it 'returns all jobs in all stages' do
      expect(subject.jobs.size).to eq 3
    end
  end

  describe '#pipeline=' do
    let(:pipeline) do
      create(:ci_empty_pipeline, ref: 'feature', tag: true)
    end

    it 'assignes relevant pipeline attributes' do
      trigger_request = pipeline.trigger_requests.first

      subject.pipeline = pipeline

      expect(subject.stages).to all(include(pipeline: pipeline))
      expect(subject.stages).to all(include(project: pipeline.project))
      expect(subject.jobs).to all(include(pipeline: pipeline))
      expect(subject.jobs).to all(include(project: pipeline.project))
      expect(subject.jobs).to all(include(ref: 'feature'))
      expect(subject.jobs).to all(include(tag: true))
      expect(subject.jobs).to all(include(trigger_request: trigger_request))
    end
  end

  describe '#user=' do
    let(:user) { create(:user) }

    it 'assignes relevant pipeline attributes' do
      subject.user = user

      expect(subject.jobs).to all(include(user: user))
    end
  end

  describe '#to_attributes' do
    it 'exposes stage attributes with nested jobs' do
      attributes = [{ name: 'test', builds_attributes:
                      [{ name: 'rspec' }, { name: 'spinach' }] },
                    { name: 'deploy', builds_attributes:
                      [{ name: 'prod', script: 'cap deploy' }] }]

      expect(subject.to_attributes).to eq attributes
    end
  end
end
