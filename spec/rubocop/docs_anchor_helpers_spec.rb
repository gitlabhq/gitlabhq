# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../rubocop/docs_anchor_helpers'

RSpec.describe RuboCop::DocsAnchorHelpers, feature_category: :tooling do
  let(:page) { 'doc/api/custom_attributes.md' }

  let(:cop) do
    Class.new do
      include RuboCop::DocsAnchorHelpers

      public :anchor_exists_in_markdown?
    end.new
  end

  before do
    cop.class.anchors_by_docs_file = {}

    allow(File).to receive(:read).with(page).and_return(<<~MARKDOWN)
      # Custom attributes

      ## Set a custom attribute
    MARKDOWN
  end

  describe '#anchor_exists_in_markdown?' do
    it 'returns true when there is no anchor to check' do
      expect(cop.anchor_exists_in_markdown?(nil, page)).to be(true)
    end

    it 'returns true when the anchor is a heading in the page' do
      expect(cop.anchor_exists_in_markdown?('set-a-custom-attribute', page)).to be(true)
    end

    it 'returns false when the anchor is not a heading in the page' do
      expect(cop.anchor_exists_in_markdown?('no-such-heading', page)).to be(false)
    end
  end
end
