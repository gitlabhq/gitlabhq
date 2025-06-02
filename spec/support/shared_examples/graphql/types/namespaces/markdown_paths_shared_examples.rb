# frozen_string_literal: true

require "spec_helper"

RSpec.shared_examples "expose all markdown paths fields for the namespace" do
  include GraphqlHelpers

  specify do
    expected_fields = %i[
      uploadsPath
      markdownPreviewPath
      autocompleteSourcesPath
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
