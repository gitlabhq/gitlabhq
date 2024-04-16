# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::WikiPageBuilder, feature_category: :wiki do
  let_it_be(:project) { create(:project) }
  let(:content) { 'test content' }
  let(:wiki_page) { create(:wiki_page, container: project, content: content) }
  let(:builder) { described_class.new(wiki_page) }

  describe '#page_content' do
    let(:page_content) { builder.page_content }
    let(:content) { 'test![WikiPage_Image](/uploads/abc/WikiPage_Image.png)' }

    it 'adds absolute urls for images in the content' do
      expected_path = "#{Settings.gitlab.url}/#{project.full_path}/-/wikis/uploads/abc/WikiPage_Image.png)"
      expect(page_content).to eq("test![WikiPage_Image](#{expected_path}")
    end
  end
end
