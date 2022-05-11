# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::IncidentManagement::TimelineEventPipeline do
  let_it_be(:project) { create(:project) }

  describe '.filters' do
    it 'contains required filters' do
      expect(described_class.filters).to eq(
        [
          *Banzai::Pipeline::PlainMarkdownPipeline.filters,
          *Banzai::Pipeline::GfmPipeline.reference_filters,
          Banzai::Filter::EmojiFilter,
          Banzai::Filter::SanitizationFilter,
          Banzai::Filter::ExternalLinkFilter,
          Banzai::Filter::ImageLinkFilter
        ]
      )
    end
  end

  describe '.to_html' do
    subject(:output) { described_class.to_html(markdown, project: project) }

    context 'when markdown contains font style transformations' do
      let(:markdown) { '**bold** _italic_ `code`' }

      it { is_expected.to eq('<p><strong>bold</strong> <em>italic</em> <code>code</code></p>') }
    end

    context 'when markdown contains banned HTML tags' do
      let(:markdown) { '<div>div</div><h1>h1</h1>' }

      it 'filters out banned tags' do
        is_expected.to eq(' div  h1 ')
      end
    end

    context 'when markdown contains links' do
      let(:markdown) { '[GitLab](https://gitlab.com)' }

      it do
        is_expected.to eq(
          %q(<p><a href="https://gitlab.com" rel="nofollow noreferrer noopener" target="_blank">GitLab</a></p>)
        )
      end
    end

    context 'when markdown contains images' do
      let(:markdown) { '![Name](/path/to/image.png)' }

      it 'replaces image with a link to the image' do
        # rubocop:disable Layout/LineLength
        is_expected.to eq(
          '<p><a class="with-attachment-icon" href="/path/to/image.png" target="_blank" rel="noopener noreferrer">Name</a></p>'
        )
        # rubocop:enable Layout/LineLength
      end
    end

    context 'when markdown contains emojis' do
      let(:markdown) { ':+1:👍' }

      it { is_expected.to eq('<p>👍👍</p>') }
    end

    context 'when markdown contains a reference to an issue' do
      let!(:issue) { create(:issue, project: project) }
      let(:markdown) { "issue ##{issue.iid}" }

      it 'contains a link to the issue' do
        is_expected.to match(%r(<p>issue <a href="[\w/]+-/issues/#{issue.iid}".*>##{issue.iid}</a></p>))
      end
    end

    context 'when markdown contains a reference to a merge request' do
      let!(:mr) { create(:merge_request, source_project: project, target_project: project) }
      let(:markdown) { "MR !#{mr.iid}" }

      it 'contains a link to the merge request' do
        is_expected.to match(%r(<p>MR <a href="[\w/]+-/merge_requests/#{mr.iid}".*>!#{mr.iid}</a></p>))
      end
    end
  end
end
