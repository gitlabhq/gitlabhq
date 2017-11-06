require 'spec_helper'

describe ChatMessage::PipelineMessage do
  subject { described_class.new(args) }

  let(:user) { { name: "The Hacker", username: 'hacker' } }
  let(:duration) { 7210 }
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
  let(:combined_name) { "The Hacker (hacker)" }

  context 'without markdown' do
    context 'pipeline succeeded' do
      let(:status) { 'success' }
      let(:color) { 'good' }
      let(:message) { build_message('passed', combined_name) }

      it 'returns a message with information about succeeded build' do
        expect(subject.pretext).to be_empty
        expect(subject.fallback).to eq(message)
        expect(subject.attachments).to eq([text: message, color: color])
      end
    end

    context 'pipeline failed' do
      let(:status) { 'failed' }
      let(:color) { 'danger' }
      let(:message) { build_message(status, combined_name) }

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
        " of branch <http://example.gitlab.com/commits/develop|develop>" \
        " by #{name} #{status_text} in 02:00:10"
    end
  end

  context 'with markdown' do
    before do
      args[:markdown] = true
    end

    context 'pipeline succeeded' do
      let(:status) { 'success' }
      let(:color) { 'good' }
      let(:message) { build_markdown_message('passed', combined_name) }

      it 'returns a message with information about succeeded build' do
        expect(subject.pretext).to be_empty
        expect(subject.attachments).to eq(message)
        expect(subject.activity).to eq({
          title: 'Pipeline [#123](http://example.gitlab.com/pipelines/123) of branch [develop](http://example.gitlab.com/commits/develop) by The Hacker (hacker) passed',
          subtitle: 'in [project_name](http://example.gitlab.com)',
          text: 'in 02:00:10',
          image: ''
        })
      end
    end

    context 'pipeline failed' do
      let(:status) { 'failed' }
      let(:color) { 'danger' }
      let(:message) { build_markdown_message(status, combined_name) }

      it 'returns a message with information about failed build' do
        expect(subject.pretext).to be_empty
        expect(subject.attachments).to eq(message)
        expect(subject.activity).to eq({
          title: 'Pipeline [#123](http://example.gitlab.com/pipelines/123) of branch [develop](http://example.gitlab.com/commits/develop) by The Hacker (hacker) failed',
          subtitle: 'in [project_name](http://example.gitlab.com)',
          text: 'in 02:00:10',
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
            title: 'Pipeline [#123](http://example.gitlab.com/pipelines/123) of branch [develop](http://example.gitlab.com/commits/develop) by API failed',
            subtitle: 'in [project_name](http://example.gitlab.com)',
            text: 'in 02:00:10',
            image: ''
          })
        end
      end
    end

    def build_markdown_message(status_text = status, name = user[:name])
      "[project_name](http://example.gitlab.com):" \
        " Pipeline [#123](http://example.gitlab.com/pipelines/123)" \
        " of branch [develop](http://example.gitlab.com/commits/develop)" \
        " by #{name} #{status_text} in 02:00:10"
    end
  end
end
