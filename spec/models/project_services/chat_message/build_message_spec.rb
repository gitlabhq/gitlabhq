require 'spec_helper'

describe ChatMessage::BuildMessage do
  subject { described_class.new(args) }

  let(:args) do
    {
      sha: '97de212e80737a608d939f648d959671fb0a0142',
      ref: 'develop',
      tag: false,

      project_name: 'project_name',
      project_url: 'http://example.gitlab.com',
      build_id: 1,
      build_name: build_name,
      build_stage: stage,

      commit: {
        status: status,
        author_name: 'hacker',
        author_url: 'http://example.gitlab.com/hacker',
        duration: duration,
      },
    }
  end

  let(:message) { build_message }
  let(:stage) { 'test' }
  let(:status) { 'success' }
  let(:build_name) { 'rspec' }
  let(:duration) { 10 }

  context 'build succeeded' do
    let(:status) { 'success' }
    let(:color) { 'good' }
    let(:message) { build_message('passed') }

    it 'returns a message with information about succeeded build' do
      expect(subject.pretext).to be_empty
      expect(subject.fallback).to eq(message)
      expect(subject.attachments).to eq([text: message, color: color])
    end
  end

  context 'build failed' do
    let(:status) { 'failed' }
    let(:color) { 'danger' }

    it 'returns a message with information about failed build' do
      expect(subject.pretext).to be_empty
      expect(subject.fallback).to eq(message)
      expect(subject.attachments).to eq([text: message, color: color])
    end
  end

  it 'returns a message with information on build' do
    expect(subject.fallback).to include("on build <http://example.gitlab.com/builds/1|#{build_name}>")
  end

  it 'returns a message with stage name' do
    expect(subject.fallback).to include("of stage #{stage}")
  end

  it 'returns a message with link to author' do
    expect(subject.fallback).to include("by <http://example.gitlab.com/hacker|hacker>")
  end

  def build_message(status_text = status, stage_text = stage, build_text = build_name)
    "<http://example.gitlab.com|project_name>:" \
    " Commit <http://example.gitlab.com/commit/" \
    "97de212e80737a608d939f648d959671fb0a0142/builds|97de212e>" \
    " of <http://example.gitlab.com/commits/develop|develop> branch" \
    " by <http://example.gitlab.com/hacker|hacker> #{status_text}" \
    " on build <http://example.gitlab.com/builds/1|#{build_text}>" \
    " of stage #{stage_text} in #{duration} #{'second'.pluralize(duration)}"
  end
end
