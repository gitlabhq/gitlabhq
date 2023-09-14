# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Sbom::Metadata, feature_category: :dependency_management do
  let(:tools) do
    [
      {
        vendor: "vendor",
        name: "Gemnasium",
        version: "2.34.0"
      }
    ]
  end

  let(:authors) do
    [
      {
        name: "author_name",
        email: "support@gitlab.com"
      }
    ]
  end

  let(:properties) do
    [
      {
        name: "property_name",
        value: "package-lock.json"
      }
    ]
  end

  let(:timestamp) { "2020-04-13T20:20:39+00:00" }

  subject(:metadata) do
    metadata = described_class.new(
      tools: tools,
      authors: authors,
      properties: properties
    )
    metadata.timestamp = timestamp
    metadata
  end

  it 'has correct attributes' do
    expect(metadata).to have_attributes(
      tools: tools,
      authors: authors,
      properties: properties,
      timestamp: timestamp
    )
  end
end
