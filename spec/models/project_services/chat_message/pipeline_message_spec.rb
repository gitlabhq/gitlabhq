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
      project: {
        path_with_namespace: 'project_name',
        web_url: 'http://example.gitlab.com'
      },
      user: user
    }
  end

  context 'without markdown' do
    context 'pipeline succeeded' do
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

    context 'pipeline failed' do
      let(:status) { 'failed' }
      let(:color) { 'danger' }
      let(:duration) { 10 }
      let(:message) { build_message }

      it 'returns a message with information about failed build' do
        expect(subject.pretext).to be_empty
        expect(subject.fallback).to eq(message)
        expect(subject.attachments).to eq([text: message, color: color])
      end

      context 'when triggered by API therefore lacking user' do
        let(:user) { nil }
        let(:message) { build_message(status, 'API') }

        it 'returns a message stating it is by API' do
          expect(subject.pretext).to be_empty
          expect(subject.fallback).to eq(message)
          expect(subject.attachments).to eq([text: message, color: color])
        end
      end
    end

    def build_message(status_text = status, name = user[:name])
      "<http://example.gitlab.com|project_name>:" \
        " Pipeline <http://example.gitlab.com/pipelines/123|#123>" \
        " of <http://example.gitlab.com/commits/develop|develop> branch" \
        " by #{name} #{status_text} in #{duration} #{'second'.pluralize(duration)}"
    end
  end

  context 'with markdown' do
    before do
      args[:markdown] = true
    end

    context 'pipeline succeeded' do
      let(:status) { 'success' }
      let(:color) { 'good' }
      let(:duration) { 10 }
      let(:message) { build_markdown_message('passed') }

      it 'returns a message with information about succeeded build' do
        expect(subject.pretext).to be_empty
        expect(subject.attachments).to eq(message)
        expect(subject.activity).to eq({
          title: 'Pipeline [#123](http://example.gitlab.com/pipelines/123) of [develop](http://example.gitlab.com/commits/develop) branch by hacker passed',
          subtitle: 'in [project_name](http://example.gitlab.com)',
          text: 'in 10 seconds',
          image: ''
        })
      end
    end

    context 'pipeline failed' do
      let(:status) { 'failed' }
      let(:color) { 'danger' }
      let(:duration) { 10 }
      let(:message) { build_markdown_message }

      it 'returns a message with information about failed build' do
        expect(subject.pretext).to be_empty
        expect(subject.attachments).to eq(message)
        expect(subject.activity).to eq({
          title: 'Pipeline [#123](http://example.gitlab.com/pipelines/123) of [develop](http://example.gitlab.com/commits/develop) branch by hacker failed',
          subtitle: 'in [project_name](http://example.gitlab.com)',
          text: 'in 10 seconds',
          image: ''
        })
      end

      context 'when triggered by API therefore lacking user' do
        let(:user) { nil }
        let(:message) { build_markdown_message(status, 'API') }

        it 'returns a message stating it is by API' do
          expect(subject.pretext).to be_empty
          expect(subject.attachments).to eq(message)
          expect(subject.activity).to eq({
            title: 'Pipeline [#123](http://example.gitlab.com/pipelines/123) of [develop](http://example.gitlab.com/commits/develop) branch by API failed',
            subtitle: 'in [project_name](http://example.gitlab.com)',
            text: 'in 10 seconds',
            image: ''
          })
        end
      end
    end

    def build_markdown_message(status_text = status, name = user[:name])
      "[project_name](http://example.gitlab.com):" \
        " Pipeline [#123](http://example.gitlab.com/pipelines/123)" \
        " of [develop](http://example.gitlab.com/commits/develop)" \
        " branch by #{name} #{status_text} in #{duration} #{'second'.pluralize(duration)}"
    end
  end
end
