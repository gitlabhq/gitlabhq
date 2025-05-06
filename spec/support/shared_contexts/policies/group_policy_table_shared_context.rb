# frozen_string_literal: true

RSpec.shared_context 'for GroupPolicyTable context' do
  using RSpec::Parameterized::TableSyntax

  include AdminModeHelper

  # group_visibility_level, :membership, :admin_mode, :expected_count
  def permission_table_for_epics_access # rubocop:disable Metrics/AbcSize -- needed for visibility specs
    :public   | :admin      | true  | 1
    :public   | :admin      | false | 1
    :public   | :admin      | true  | 1
    :public   | :admin      | false | 1
    :public   | :planner    | nil   | 1
    :public   | :reporter   | nil   | 1
    :public   | :guest      | nil   | 1
    :public   | :non_member | nil   | 1
    :public   | :anonymous  | nil   | 1

    :internal | :admin      | true  | 1
    :internal | :admin      | false | 1
    :internal | :reporter   | nil   | 1
    :internal | :planner    | nil   | 1
    :internal | :guest      | nil   | 1
    :internal | :non_member | nil   | 1
    :internal | :anonymous  | nil   | 0

    :private  | :admin      | true  | 1
    :private  | :admin      | false | 0
    :private  | :reporter   | nil   | 1
    :private  | :planner    | nil   | 1
    :private  | :guest      | nil   | 1
    :private  | :non_member | nil   | 0
    :private  | :anonymous  | nil   | 0
  end
end
