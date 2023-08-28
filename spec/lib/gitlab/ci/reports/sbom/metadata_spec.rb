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

  subject(:metadata) do
    described_class.new(
      tools: tools,
      authors: authors,
      properties: properties
    )
  end

  it 'has correct attributes' do
    expect(metadata).to have_attributes(
      tools: tools,
      authors: authors,
      properties: properties
    )
  end
end
