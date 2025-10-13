# frozen_string_literal: true

RSpec.shared_context 'for ConfidentialityWorkItemsTable context' do
  using RSpec::Parameterized::TableSyntax

  include AdminModeHelper

  # rubocop:disable Metrics/AbcSize -- this table is a shared context

  # This table is tests work item confidentiality for work items.
  # Use it with the 'search respects visibility' shared example.
  # It is required on the context to have three named `let` variables named:
  #   - `non_confidential`: one regular work item
  #   - `confidential`: one confidential work item (no assignee)
  #   - `confidential_user_as_assignee`: one confidential work item (no assignee, shared example will set assignee)
  #   - `confidential_user_as_author`: one confidential work item (shared example will set author)
  # Note: The `feature_access_level` is tested with the default setting for the project or group visibility level.
  #
  # visibility_level, :feature_access_level, :membership, :admin_mode, :expected_count
  def confidentiality_table_for_work_item_access
    :public   | :enabled  | :admin      | true  | 4
    :public   | :enabled  | :admin      | false | 3 # non-confidential, assigned, author
    :public   | :enabled  | :planner    | nil   | 4
    :public   | :enabled  | :guest      | nil   | 3 # non-confidential, assigned, author
    :public   | :enabled  | :non_member | nil   | 3 # non-confidential, assigned, author
    :public   | :enabled  | :anonymous  | nil   | 1 # non-confidential

    :internal | :enabled  | :admin      | true  | 4
    :internal | :enabled  | :admin      | false | 3 # non-confidential, assigned, author
    :internal | :enabled  | :planner    | nil   | 4
    :internal | :enabled  | :guest      | nil   | 3 # non-confidential, assigned, author
    :internal | :enabled  | :non_member | nil   | 3 # non-confidential, assigned, author
    :internal | :enabled  | :anonymous  | nil   | 0

    :private  | :private  | :admin      | true  | 4
    :private  | :private  | :admin      | false | 0
    :private  | :private  | :planner    | nil   | 4
    :private  | :private  | :guest      | nil   | 3 # non-confidential, assigned, author
    :private  | :private  | :non_member | nil   | 0
    :private  | :private  | :anonymous  | nil   | 0
  end
  # rubocop:enable Metrics/AbcSize
end
