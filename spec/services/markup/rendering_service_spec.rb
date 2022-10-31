# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Markup::RenderingService do
  describe '#execute' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) do
      user = create(:user, username: 'gfm')
      project.add_maintainer(user)
      user
    end

    let_it_be(:context) { { project: project } }
    let_it_be(:postprocess_context) { { current_user: user } }

    let(:file_name) { nil }
    let(:text) { 'Noël' }

    subject do
      described_class
        .new(text, file_name: file_name, context: context, postprocess_context: postprocess_context)
        .execute
    end

    context 'when text is missing' do
      let(:text) { nil }

      it 'returns an empty string' do
        is_expected.to eq('')
      end
    end

    context 'when file_name is missing' do
      it 'returns html (rendered by Banzai)' do
        expected_html = '<p data-sourcepos="1:1-1:5" dir="auto">Noël</p>'

        expect(Banzai).to receive(:render).with(text, context) { expected_html }

        is_expected.to eq(expected_html)
      end
    end

    context 'when postprocess_context is missing' do
      let(:file_name) { 'foo.txt' }
      let(:postprocess_context) { nil }

      it 'returns html (rendered by Banzai)' do
        expected_html = '<pre class="plain-readme">Noël</pre>'

        expect(Banzai).not_to receive(:post_process) { expected_html }

        is_expected.to eq(expected_html)
      end
    end

    context 'when rendered context is present' do
      let(:rendered) { 'rendered text' }
      let(:file_name) { 'foo.md' }

      it 'returns an empty string' do
        context[:rendered] = rendered

        is_expected.to eq(rendered)
      end
    end

    context 'when file is a markdown file' do
      let(:file_name) { 'foo.md' }

      it 'returns html (rendered by Banzai)' do
        expected_html = '<p data-sourcepos="1:1-1:5" dir="auto">Noël</p>'

        expect(Banzai).to receive(:render).with(text, context) { expected_html }

        is_expected.to eq(expected_html)
      end

      context 'when renderer returns an error' do
        before do
          allow(Banzai).to receive(:render).and_raise(StandardError, "An error")
        end

        it 'returns html (rendered by ActionView:TextHelper)' do
          is_expected.to eq('<p>Noël</p>')
        end

        it 'logs the error' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            instance_of(StandardError),
            project_id: context[:project].id, file_name: 'foo.md'
          )

          subject
        end
      end
    end

    context 'when file is asciidoc file' do
      let(:file_name) { 'foo.adoc' }

      it 'returns html (rendered by Gitlab::Asciidoc)' do
        expected_html = "<div>\n<p>Noël</p>\n</div>"

        expect(Gitlab::Asciidoc).to receive(:render).with(text, context) { expected_html }

        is_expected.to eq(expected_html)
      end
    end

    context 'when file is a regular text file' do
      let(:file_name) { 'foo.txt' }

      it 'returns html (rendered by ActionView::TagHelper)' do
        is_expected.to eq('<pre class="plain-readme">Noël</pre>')
      end
    end

    context 'when file has an unknown type' do
      let(:file_name) { 'foo.tex' }

      it 'returns html (rendered by Gitlab::OtherMarkup)' do
        expected_html = 'Noël'

        expect(Gitlab::OtherMarkup).to receive(:render).with(file_name, text, context) { expected_html }

        is_expected.to eq(expected_html)
      end
    end

    context 'when rendering takes too long' do
      let(:file_name) { 'foo.bar' }

      before do
        stub_const("Markup::RenderingService::RENDER_TIMEOUT", 0.1)
        allow(Gitlab::OtherMarkup).to receive(:render) do
          sleep(0.2)
          text
        end
      end

      it 'times out' do
        expect(Gitlab::RenderTimeout).to receive(:timeout).and_call_original
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          instance_of(Timeout::Error),
          project_id: context[:project].id, file_name: file_name
        )

        is_expected.to eq("<p>#{text}</p>")
      end

      context 'when markup_rendering_timeout is disabled' do
        it 'waits until the execution completes' do
          stub_feature_flags(markup_rendering_timeout: false)

          expect(Gitlab::RenderTimeout).not_to receive(:timeout)

          is_expected.to eq(text)
        end
      end
    end
  end
end
