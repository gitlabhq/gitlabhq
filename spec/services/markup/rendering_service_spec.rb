# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Markup::RenderingService, feature_category: :groups_and_projects do
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
      let(:text) { 'Noël <form>' }

      it 'returns html (rendered by ActionView::TagHelper)' do
        expect(ActionController::Base.helpers).to receive(:content_tag).and_call_original

        is_expected.to eq('<pre class="plain-readme">Noël &lt;form&gt;</pre>')
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

    context 'with reStructuredText' do
      let(:file_name) { 'foo.rst' }
      let(:text) { "####\nPART\n####" }

      it 'returns rendered html' do
        is_expected.to eq("<h1>PART</h1>\n\n")
      end

      context 'when input has an invalid syntax' do
        let(:text) { "####\nPART\n##" }

        it 'uses a simple formatter for html' do
          is_expected.to eq("<p>####\n<br>PART\n<br>##</p>")
        end
      end
    end
  end
end
