# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Audit::OrbitIndexerAuthor, feature_category: :knowledge_graph do
  subject(:author) { described_class.new }

  it 'is attributed to the Orbit indexer with its own sentinel id' do
    expect(author).to have_attributes(id: -4, name: 'GitLab Orbit Indexer')
  end

  it 'is not impersonated' do
    expect(author.impersonated?).to be(false)
  end
end
