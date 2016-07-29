require 'spec_helper'

describe SlackService::PipelineMessage do
  subject { SlackService::PipelineMessage.new(args) }

  let(:args) do
    {
      sha: '97de212e80737a608d939f648d959671fb0a0142',
      tag: false,
      ref: 'develop',
      status: status,
      project: { path_with_namespace: 'project_name',
                 web_url: 'somewhere.com' },
      commit: { author_name: 'hacker' },
      object_attributes: { duration: duration,
                           id: 123 }
    }
  end

  context 'succeeded' do
    let(:status) { 'success' }
    let(:color) { 'good' }
    let(:duration) { 10 }

    it 'returns a message with information about succeeded build' do
      message = '<somewhere.com|project_name>: Pipeline <somewhere.com/pipelines/123|97de212e> of <somewhere.com/commits/develop|develop> branch by hacker passed in 10 seconds'
      expect(subject.pretext).to be_empty
      expect(subject.fallback).to eq(message)
      expect(subject.attachments).to eq([text: message, color: color])
    end
  end

  context 'failed' do
    let(:status) { 'failed' }
    let(:color) { 'danger' }
    let(:duration) { 10 }

    it 'returns a message with information about failed build' do
      message = '<somewhere.com|project_name>: Pipeline <somewhere.com/pipelines/123|97de212e> of <somewhere.com/commits/develop|develop> branch by hacker failed in 10 seconds'
      expect(subject.pretext).to be_empty
      expect(subject.fallback).to eq(message)
      expect(subject.attachments).to eq([text: message, color: color])
    end
  end

  describe '#seconds_name' do
    let(:status) { 'failed' }
    let(:color) { 'danger' }
    let(:duration) { 1 }

    it 'returns seconds as singular when there is only one' do
      message = '<somewhere.com|project_name>: Pipeline <somewhere.com/pipelines/123|97de212e> of <somewhere.com/commits/develop|develop> branch by hacker failed in 1 second'
      expect(subject.pretext).to be_empty
      expect(subject.fallback).to eq(message)
      expect(subject.attachments).to eq([text: message, color: color])
    end
  end
end
