require 'spec_helper'

describe SlackService::BuildMessage do
  subject { SlackService::BuildMessage.new(args) }

  let(:args) do
    {
      sha: '97de212e80737a608d939f648d959671fb0a0142',
      ref: 'develop',
      tag: false,

      project_name: 'project_name',
      project_url: 'example.gitlab.com',

      commit: {
        status: status,
        author_name: 'hacker',
        duration: duration,
      },
    }
  end

  context 'succeeded' do
    let(:status) { 'success' }
    let(:color) { 'good' }
    let(:duration) { 10 }

    it 'returns a message with information about succeeded build' do
      message = '<example.gitlab.com|project_name>: Commit <example.gitlab.com/commit/97de212e80737a608d939f648d959671fb0a0142/builds|97de212e> of <example.gitlab.com/commits/develop|develop> branch by hacker passed in 10 seconds'

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
      message = '<example.gitlab.com|project_name>: Commit <example.gitlab.com/commit/97de212e80737a608d939f648d959671fb0a0142/builds|97de212e> of <example.gitlab.com/commits/develop|develop> branch by hacker failed in 10 seconds'

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
      message = '<example.gitlab.com|project_name>: Commit <example.gitlab.com/commit/97de212e80737a608d939f648d959671fb0a0142/builds|97de212e> of <example.gitlab.com/commits/develop|develop> branch by hacker failed in 1 second'

      expect(subject.pretext).to be_empty
      expect(subject.fallback).to eq(message)
      expect(subject.attachments).to eq([text: message, color: color])
    end
  end
end
