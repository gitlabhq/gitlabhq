# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TaggableQueries do
  it 'keeps MAX_TAGS_IDS in sync with TAGS_LIMIT' do
    expect(described_class::MAX_TAGS_IDS).to eq(Gitlab::Ci::Config::Entry::Tags::TAGS_LIMIT)
  end
end
