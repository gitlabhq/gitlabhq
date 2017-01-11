require 'spec_helper'

describe ChatMessage::PipelineMessage do
  subject { described_class.new(args) }

  let(:user) { { name: 'hacker' } }

  let(:args) do
    {
      object_attributes: {
        id: 123,
        sha: '97de212e80737a608d939f648d959671fb0a0142',
        tag: false,
        ref: 'develop',
        status: status,
        duration: duration
      },
      project: { path_with_namespace: 'project_name',
                 web_url: 'http://example.gitlab.com' },
      user: user
    }
  end

  let(:message) { build_message }

  context 'pipeline succeeded' do
    let(:status) { 'success' }
    let(:color) { 'good' }
    let(:duration) { 10 }
    let(:message) { build_message('passed') }

    it 'returns a message with information about succeeded build' do
      verify_message
    end
  end

  context 'pipeline failed' do
    let(:status) { 'failed' }
    let(:color) { 'danger' }
    let(:duration) { 10 }

    it 'returns a message with information about failed build' do
      verify_message
    end

    context 'when triggered by API therefore lacking user' do
      let(:user) { nil }
      let(:message) { build_message(status, 'API') }

      it 'returns a message stating it is by API' do
        verify_message
      end
    end
  end

  def verify_message
    expect(subject.pretext).to be_empty
    expect(subject.fallback).to eq(message)
    expect(subject.attachments).to eq([text: message, color: color])
  end

  def build_message(status_text = status, name = user[:name])
    "<http://example.gitlab.com|project_name>:" \
    " Pipeline <http://example.gitlab.com/pipelines/123|#123>" \
    " of <http://example.gitlab.com/commits/develop|develop> branch" \
    " by #{name} #{status_text} in #{duration} #{'second'.pluralize(duration)}"
  end
end
