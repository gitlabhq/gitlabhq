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

  let(:message) { build_message }

  context 'succeeded' do
    let(:status) { 'success' }
    let(:color) { 'good' }
    let(:duration) { 10 }
    let(:message) { build_message('passed') }

    it 'returns a message with information about succeeded build' do
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
      expect(subject.pretext).to be_empty
      expect(subject.fallback).to eq(message)
      expect(subject.attachments).to eq([text: message, color: color])
    end
  end

  def build_message(status_text=status)
    "<example.gitlab.com|project_name>:" \
    " Commit <example.gitlab.com/commit/" \
    "97de212e80737a608d939f648d959671fb0a0142/builds|97de212e>" \
    " of <example.gitlab.com/commits/develop|develop> branch" \
    " by hacker #{status_text} in #{duration} #{'second'.pluralize(duration)}"
  end
end
