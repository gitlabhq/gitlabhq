# frozen_string_literal: true

RSpec.shared_context 'ProjectPolicyTable context' do
  using RSpec::Parameterized::TableSyntax

  # rubocop:disable Metrics/AbcSize
  def permission_table_for_reporter_feature_access
    :public   | :enabled  | :reporter   | 1
    :public   | :enabled  | :guest      | 1
    :public   | :enabled  | :non_member | 1
    :public   | :enabled  | :anonymous  | 1

    :public   | :private  | :reporter   | 1
    :public   | :private  | :guest      | 0
    :public   | :private  | :non_member | 0
    :public   | :private  | :anonymous  | 0

    :public   | :disabled | :reporter   | 0
    :public   | :disabled | :guest      | 0
    :public   | :disabled | :non_member | 0
    :public   | :disabled | :anonymous  | 0

    :internal | :enabled  | :reporter   | 1
    :internal | :enabled  | :guest      | 1
    :internal | :enabled  | :non_member | 1
    :internal | :enabled  | :anonymous  | 0

    :internal | :private  | :reporter   | 1
    :internal | :private  | :guest      | 0
    :internal | :private  | :non_member | 0
    :internal | :private  | :anonymous  | 0

    :internal | :disabled | :reporter   | 0
    :internal | :disabled | :guest      | 0
    :internal | :disabled | :non_member | 0
    :internal | :disabled | :anonymous  | 0

    :private  | :enabled  | :reporter   | 1
    :private  | :enabled  | :guest      | 1
    :private  | :enabled  | :non_member | 0
    :private  | :enabled  | :anonymous  | 0

    :private  | :private  | :reporter   | 1
    :private  | :private  | :guest      | 0
    :private  | :private  | :non_member | 0
    :private  | :private  | :anonymous  | 0

    :private  | :disabled | :reporter   | 0
    :private  | :disabled | :guest      | 0
    :private  | :disabled | :non_member | 0
    :private  | :disabled | :anonymous  | 0
  end

  def permission_table_for_guest_feature_access
    :public   | :enabled  | :reporter   | 1
    :public   | :enabled  | :guest      | 1
    :public   | :enabled  | :non_member | 1
    :public   | :enabled  | :anonymous  | 1

    :public   | :private  | :reporter   | 1
    :public   | :private  | :guest      | 1
    :public   | :private  | :non_member | 0
    :public   | :private  | :anonymous  | 0

    :public   | :disabled | :reporter   | 0
    :public   | :disabled | :guest      | 0
    :public   | :disabled | :non_member | 0
    :public   | :disabled | :anonymous  | 0

    :internal | :enabled  | :reporter   | 1
    :internal | :enabled  | :guest      | 1
    :internal | :enabled  | :non_member | 1
    :internal | :enabled  | :anonymous  | 0

    :internal | :private  | :reporter   | 1
    :internal | :private  | :guest      | 1
    :internal | :private  | :non_member | 0
    :internal | :private  | :anonymous  | 0

    :internal | :disabled | :reporter   | 0
    :internal | :disabled | :guest      | 0
    :internal | :disabled | :non_member | 0
    :internal | :disabled | :anonymous  | 0

    :private  | :enabled  | :reporter   | 1
    :private  | :enabled  | :guest      | 1
    :private  | :enabled  | :non_member | 0
    :private  | :enabled  | :anonymous  | 0

    :private  | :private  | :reporter   | 1
    :private  | :private  | :guest      | 1
    :private  | :private  | :non_member | 0
    :private  | :private  | :anonymous  | 0

    :private  | :disabled | :reporter   | 0
    :private  | :disabled | :guest      | 0
    :private  | :disabled | :non_member | 0
    :private  | :disabled | :anonymous  | 0
  end

  def permission_table_for_project_access
    :public   | :reporter   | 1
    :public   | :guest      | 1
    :public   | :non_member | 1
    :public   | :anonymous  | 1

    :internal | :reporter   | 1
    :internal | :guest      | 1
    :internal | :non_member | 1
    :internal | :anonymous  | 0

    :private  | :reporter   | 1
    :private  | :guest      | 1
    :private  | :non_member | 0
    :private  | :anonymous  | 0
  end
  # rubocop:enable Metrics/AbcSize
end
