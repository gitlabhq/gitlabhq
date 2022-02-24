# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WikiPage do
  let_it_be_with_reload(:wiki_page) { create(:wiki_page) }

  let(:entity) { described_class.new(wiki_page) }

  it 'returns the proper encoding for the wiki page content' do
    expect(entity.as_json[:encoding]).to eq 'UTF-8'

    wiki_page.update_attributes(content: 'new_content'.encode('ISO-8859-1')) # rubocop:disable Rails/ActiveRecordAliases, Rails/SaveBang

    expect(entity.as_json[:encoding]).to eq 'ISO-8859-1'
  end
end
