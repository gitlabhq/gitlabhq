# frozen_string_literal: true

require "spec_helper"

RSpec.shared_examples "expose all licensed feature fields for the namespace" do
  include GraphqlHelpers

  specify do
    expected_fields = %i[has_issue_weights_feature has_iterations_feature has_okrs_feature has_subepics_feature
      has_issuable_health_status_feature has_epics_feature has_scoped_labels_feature has_quality_management_feature
      has_linked_items_epics_feature has_issue_date_filter_feature]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
