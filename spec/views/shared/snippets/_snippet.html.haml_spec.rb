# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/snippets/_snippet.html.haml' do
  let_it_be(:snippet) { create(:snippet) }

  before do
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
    allow(view).to receive(:can?) { true }

    @noteable_meta_data = Class.new { include Gitlab::NoteableMetadata }.new.noteable_meta_data([snippet], 'Snippet')
  end

  context 'snippet with statistics' do
    it 'renders correct file count and tooltip' do
      snippet.statistics.file_count = 3

      render 'shared/snippets/snippet', snippet: snippet

      expect(rendered).to have_selector("span.file_count", text: '3')
      expect(rendered).to have_selector("span.file_count[title=\"3 files\"]")
    end

    it 'renders correct file count and tooltip when file_count is 1' do
      snippet.statistics.file_count = 1

      render 'shared/snippets/snippet', snippet: snippet

      expect(rendered).to have_selector("span.file_count", text: '1')
      expect(rendered).to have_selector("span.file_count[title=\"1 file\"]")
    end

    it 'does not render file count when file count is 0' do
      snippet.statistics.file_count = 0

      render 'shared/snippets/snippet', snippet: snippet

      expect(rendered).not_to have_selector('span.file_count')
    end
  end

  context 'snippet without statistics' do
    it 'does not render file count if statistics are not present' do
      snippet.statistics = nil

      render 'shared/snippets/snippet', snippet: snippet

      expect(rendered).not_to have_selector('span.file_count')
    end
  end
end
