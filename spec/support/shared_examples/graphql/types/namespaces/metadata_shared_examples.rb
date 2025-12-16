# frozen_string_literal: true

RSpec.shared_examples "expose all metadata fields for the namespace" do
  include GraphqlHelpers

  specify do
    # Base fields that all namespace metadata types must have
    expected_fields = %i[
      timeTrackingLimitToHours
      initialSort
      isIssueRepositioningDisabled
      showNewWorkItem
      maxAttachmentSize
      groupId
    ]

    expected_fields.push(*type_specific_fields) if defined?(type_specific_fields)

    expect(described_class).to have_graphql_fields(*expected_fields).at_least
  end
end

RSpec.shared_examples "common namespace metadata values" do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  before do
    allow(Gitlab::CurrentSettings).to receive(:max_attachment_size).and_return(10)
  end

  where(:field, :value) do
    :time_tracking_limit_to_hours | lazy { Gitlab::CurrentSettings.time_tracking_limit_to_hours }
    :initial_sort | lazy { user.user_preference&.issues_sort }
    :max_attachment_size | "10 MiB"
  end

  with_them do
    it { expect(resolve_field(field, namespace, current_user: user)).to eq(value) }
  end
end
