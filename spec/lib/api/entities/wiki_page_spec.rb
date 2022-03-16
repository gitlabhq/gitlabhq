# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WikiPage do
  let_it_be_with_reload(:wiki_page) { create(:wiki_page) }

  let(:params) { {} }
  let(:entity) { described_class.new(wiki_page, params) }

  subject { entity.as_json }

  it 'returns the proper encoding for the wiki page content' do
    expect(entity.as_json[:encoding]).to eq 'UTF-8'

    wiki_page.update_attributes(content: 'new_content'.encode('ISO-8859-1')) # rubocop:disable Rails/ActiveRecordAliases, Rails/SaveBang

    expect(entity.as_json[:encoding]).to eq 'ISO-8859-1'
  end

  it 'returns the raw wiki page content' do
    expect(subject[:content]).to eq wiki_page.content
  end

  context 'when render_html param is passed' do
    context 'when it is true' do
      let(:params) { { render_html: true } }

      it 'returns the wiki page content rendered' do
        expect(subject[:content]).to eq "<p data-sourcepos=\"1:1-1:#{wiki_page.content.size}\" dir=\"auto\">#{wiki_page.content}</p>"
      end

      it 'includes the wiki page version in the render context' do
        expect(entity).to receive(:render_wiki_content).with(anything, hash_including(ref: wiki_page.version.id)).and_call_original

        subject[:content]
      end

      context 'when page is an Ascii document' do
        let(:wiki_page) { create(:wiki_page, content: "*Test* _content_", format: :asciidoc) }

        it 'renders the page without errors' do
          expect(subject[:content]).to eq("<div>&#x000A;<p><strong>Test</strong> <em>content</em></p>&#x000A;</div>")
        end
      end
    end

    context 'when it is false' do
      let(:params) { { render_html: false } }

      it 'returns the raw wiki page content' do
        expect(subject[:content]).to eq wiki_page.content
      end
    end
  end
end
