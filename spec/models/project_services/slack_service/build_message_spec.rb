require 'spec_helper'

describe SlackService::BuildMessage do
  subject { SlackService::BuildMessage.new(args) }

  let(:args) do
    {
      sha: '97de212e80737a608d939f648d959671fb0a0142',
      ref: 'develop',
      tag: false,

      project_name: 'project_name',
      project_url: 'somewhere.com',

      commit: {
        status: status,
        author_name: 'hacker',
        duration: 10,
      },
    }
  end

  context 'succeeded' do
    let(:status) { 'success' }
    let(:color) { 'good' }

    it 'returns a message with information about succeeded build' do
      message = '<somewhere.com|project_name>: Commit <somewhere.com/commit/97de212e80737a608d939f648d959671fb0a0142/builds|97de212e> of <somewhere.com/commits/develop|develop> branch by hacker passed in 10 second(s)'
      expect(subject.pretext).to be_empty
      expect(subject.fallback).to eq(message)
      expect(subject.attachments).to eq([text: message, color: color])
    end
  end

  context 'failed' do
    let(:status) { 'failed' }
    let(:color) { 'danger' }

    it 'returns a message with information about failed build' do
      message = '<somewhere.com|project_name>: Commit <somewhere.com/commit/97de212e80737a608d939f648d959671fb0a0142/builds|97de212e> of <somewhere.com/commits/develop|develop> branch by hacker failed in 10 second(s)'
      expect(subject.pretext).to be_empty
      expect(subject.fallback).to eq(message)
      expect(subject.attachments).to eq([text: message, color: color])
    end
  end
end
