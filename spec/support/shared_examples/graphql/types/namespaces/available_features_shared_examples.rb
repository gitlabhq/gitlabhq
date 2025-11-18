# frozen_string_literal: true

require "spec_helper"

RSpec.shared_examples "expose all available feature fields for the namespace" do
  include GraphqlHelpers

  specify do
    expected_fields = %i[
      has_blocked_issues_feature
      has_custom_fields_feature
      has_design_management_feature
      has_epics_feature
      has_group_bulk_edit_feature
      has_issuable_health_status_feature
      has_issue_date_filter_feature
      has_issue_weights_feature
      has_iterations_feature
      has_linked_items_epics_feature
      has_okrs_feature
      has_quality_management_feature
      has_scoped_labels_feature
      has_subepics_feature
      has_work_item_status_feature
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
