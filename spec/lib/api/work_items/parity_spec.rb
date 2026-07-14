# frozen_string_literal: true

require 'spec_helper'

# We expect more fields in EE, so we have a shared spec between CE and EE with different
# expectations about the fields. Since the CE test also runs in EE, we need to skip it.
RSpec.describe 'Work item API parity', feature_category: :team_planning, unless: Gitlab.ee? do
  it_behaves_like 'work item API field parity' do
    # linked_items is exposed in REST only via the EE entity (blocking_count / blocked_by_count).
    # In CE there is no REST exposure, so it remains a GraphQL-only feature.
    let(:extra_graphql_feature_exceptions) { Set.new(%w[linked_items]) }
  end

  it_behaves_like 'work item API filter parity'

  it_behaves_like 'work item API create parity' do
    # development_widget is exposed only on the GraphQL create mutation (links MRs to
    # the new work item); the REST create endpoint has no development feature param.
    let(:widget_exceptions) { Set.new(%w[development_widget]) }
  end
end
