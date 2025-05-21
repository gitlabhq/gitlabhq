# frozen_string_literal: true

require "spec_helper"

RSpec.shared_examples "expose all user permissions fields for the namespace" do
  include GraphqlHelpers

  specify do
    expected_fields = %i[
      canAdminLabel
      canCreateProjects
    ]

    if Gitlab.ee?
      expected_fields.push(*%i[
        canCreateEpic
        canBulkEditEpics
      ])
    end

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
