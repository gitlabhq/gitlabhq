# frozen_string_literal: true

RSpec.shared_context 'ProjectPolicyTable context' do
  using RSpec::Parameterized::TableSyntax

  let(:pendings) { {} }
  let(:pending?) do
    pendings.include?(
      {
        project_level: project_level,
        feature_access_level: feature_access_level,
        membership: membership,
        expected_count: expected_count
      }
    )
  end

  # rubocop:disable Metrics/AbcSize
  # project_level, :feature_access_level, :membership, :expected_count
  def permission_table_for_reporter_feature_access
    :public   | :enabled  | :admin      | 1
    :public   | :enabled  | :reporter   | 1
    :public   | :enabled  | :guest      | 1
    :public   | :enabled  | :non_member | 1
    :public   | :enabled  | :anonymous  | 1

    :public   | :private  | :admin      | 1
    :public   | :private  | :reporter   | 1
    :public   | :private  | :guest      | 0
    :public   | :private  | :non_member | 0
    :public   | :private  | :anonymous  | 0

    :public   | :disabled | :reporter   | 0
    :public   | :disabled | :guest      | 0
    :public   | :disabled | :non_member | 0
    :public   | :disabled | :anonymous  | 0

    :internal | :enabled  | :admin      | 1
    :internal | :enabled  | :reporter   | 1
    :internal | :enabled  | :guest      | 1
    :internal | :enabled  | :non_member | 1
    :internal | :enabled  | :anonymous  | 0

    :internal | :private  | :admin      | 1
    :internal | :private  | :reporter   | 1
    :internal | :private  | :guest      | 0
    :internal | :private  | :non_member | 0
    :internal | :private  | :anonymous  | 0

    :internal | :disabled | :reporter   | 0
    :internal | :disabled | :guest      | 0
    :internal | :disabled | :non_member | 0
    :internal | :disabled | :anonymous  | 0

    :private  | :private  | :admin      | 1
    :private  | :private  | :reporter   | 1
    :private  | :private  | :guest      | 0
    :private  | :private  | :non_member | 0
    :private  | :private  | :anonymous  | 0

    :private  | :disabled | :reporter   | 0
    :private  | :disabled | :guest      | 0
    :private  | :disabled | :non_member | 0
    :private  | :disabled | :anonymous  | 0
  end

  # project_level, :feature_access_level, :membership, :expected_count
  def permission_table_for_guest_feature_access
    :public   | :enabled  | :admin      | 1
    :public   | :enabled  | :reporter   | 1
    :public   | :enabled  | :guest      | 1
    :public   | :enabled  | :non_member | 1
    :public   | :enabled  | :anonymous  | 1

    :public   | :private  | :admin      | 1
    :public   | :private  | :reporter   | 1
    :public   | :private  | :guest      | 1
    :public   | :private  | :non_member | 0
    :public   | :private  | :anonymous  | 0

    :public   | :disabled | :reporter   | 0
    :public   | :disabled | :guest      | 0
    :public   | :disabled | :non_member | 0
    :public   | :disabled | :anonymous  | 0

    :internal | :enabled  | :admin      | 1
    :internal | :enabled  | :reporter   | 1
    :internal | :enabled  | :guest      | 1
    :internal | :enabled  | :non_member | 1
    :internal | :enabled  | :anonymous  | 0

    :internal | :private  | :admin      | 1
    :internal | :private  | :reporter   | 1
    :internal | :private  | :guest      | 1
    :internal | :private  | :non_member | 0
    :internal | :private  | :anonymous  | 0

    :internal | :disabled | :reporter   | 0
    :internal | :disabled | :guest      | 0
    :internal | :disabled | :non_member | 0
    :internal | :disabled | :anonymous  | 0

    :private  | :private  | :admin      | 1
    :private  | :private  | :reporter   | 1
    :private  | :private  | :guest      | 1
    :private  | :private  | :non_member | 0
    :private  | :private  | :anonymous  | 0

    :private  | :disabled | :reporter   | 0
    :private  | :disabled | :guest      | 0
    :private  | :disabled | :non_member | 0
    :private  | :disabled | :anonymous  | 0
  end

  # This table is based on permission_table_for_guest_feature_access,
  # but with a slight twist.
  # Some features can be hidden away to GUEST, when project is private.
  # (see ProjectFeature::PRIVATE_FEATURES_MIN_ACCESS_LEVEL_FOR_PRIVATE_PROJECT)
  # This is the table for such features.
  #
  # e.g. `repository` feature has minimum requirement of GUEST,
  # but a GUEST are prohibited from reading code if project is private.
  #
  # project_level, :feature_access_level, :membership, :expected_count
  def permission_table_for_guest_feature_access_and_non_private_project_only
    :public   | :enabled  | :admin      | 1
    :public   | :enabled  | :reporter   | 1
    :public   | :enabled  | :guest      | 1
    :public   | :enabled  | :non_member | 1
    :public   | :enabled  | :anonymous  | 1

    :public   | :private  | :admin      | 1
    :public   | :private  | :reporter   | 1
    :public   | :private  | :guest      | 1
    :public   | :private  | :non_member | 0
    :public   | :private  | :anonymous  | 0

    :public   | :disabled | :reporter   | 0
    :public   | :disabled | :guest      | 0
    :public   | :disabled | :non_member | 0
    :public   | :disabled | :anonymous  | 0

    :internal | :enabled  | :admin      | 1
    :internal | :enabled  | :reporter   | 1
    :internal | :enabled  | :guest      | 1
    :internal | :enabled  | :non_member | 1
    :internal | :enabled  | :anonymous  | 0

    :internal | :private  | :admin      | 1
    :internal | :private  | :reporter   | 1
    :internal | :private  | :guest      | 1
    :internal | :private  | :non_member | 0
    :internal | :private  | :anonymous  | 0

    :internal | :disabled | :reporter   | 0
    :internal | :disabled | :guest      | 0
    :internal | :disabled | :non_member | 0
    :internal | :disabled | :anonymous  | 0

    :private  | :private  | :admin      | 1
    :private  | :private  | :reporter   | 1
    :private  | :private  | :guest      | 0
    :private  | :private  | :non_member | 0
    :private  | :private  | :anonymous  | 0

    :private  | :disabled | :reporter   | 0
    :private  | :disabled | :guest      | 0
    :private  | :disabled | :non_member | 0
    :private  | :disabled | :anonymous  | 0
  end

  # :project_level, :issues_access_level, :merge_requests_access_level, :membership, :expected_count
  def permission_table_for_milestone_access
    :public   | :enabled  | :enabled  | :admin      | 1
    :public   | :enabled  | :enabled  | :reporter   | 1
    :public   | :enabled  | :enabled  | :guest      | 1
    :public   | :enabled  | :enabled  | :non_member | 1
    :public   | :enabled  | :enabled  | :anonymous  | 1

    :public   | :enabled  | :private  | :admin      | 1
    :public   | :enabled  | :private  | :reporter   | 1
    :public   | :enabled  | :private  | :guest      | 1
    :public   | :enabled  | :private  | :non_member | 1
    :public   | :enabled  | :private  | :anonymous  | 1

    :public   | :enabled  | :disabled | :admin      | 1
    :public   | :enabled  | :disabled | :reporter   | 1
    :public   | :enabled  | :disabled | :guest      | 1
    :public   | :enabled  | :disabled | :non_member | 1
    :public   | :enabled  | :disabled | :anonymous  | 1

    :public   | :private  | :enabled  | :admin      | 1
    :public   | :private  | :enabled  | :reporter   | 1
    :public   | :private  | :enabled  | :guest      | 1
    :public   | :private  | :enabled  | :non_member | 1
    :public   | :private  | :enabled  | :anonymous  | 1

    :public   | :private  | :private  | :admin      | 1
    :public   | :private  | :private  | :reporter   | 1
    :public   | :private  | :private  | :guest      | 1
    :public   | :private  | :private  | :non_member | 0
    :public   | :private  | :private  | :anonymous  | 0

    :public   | :private  | :disabled | :admin      | 1
    :public   | :private  | :disabled | :reporter   | 1
    :public   | :private  | :disabled | :guest      | 1
    :public   | :private  | :disabled | :non_member | 0
    :public   | :private  | :disabled | :anonymous  | 0

    :public   | :disabled | :enabled  | :admin      | 1
    :public   | :disabled | :enabled  | :reporter   | 1
    :public   | :disabled | :enabled  | :guest      | 1
    :public   | :disabled | :enabled  | :non_member | 1
    :public   | :disabled | :enabled  | :anonymous  | 1

    :public   | :disabled | :private  | :admin      | 1
    :public   | :disabled | :private  | :reporter   | 1
    :public   | :disabled | :private  | :guest      | 0
    :public   | :disabled | :private  | :non_member | 0
    :public   | :disabled | :private  | :anonymous  | 0

    :public   | :disabled | :disabled | :reporter   | 0
    :public   | :disabled | :disabled | :guest      | 0
    :public   | :disabled | :disabled | :non_member | 0
    :public   | :disabled | :disabled | :anonymous  | 0

    :internal | :enabled  | :enabled  | :admin      | 1
    :internal | :enabled  | :enabled  | :reporter   | 1
    :internal | :enabled  | :enabled  | :guest      | 1
    :internal | :enabled  | :enabled  | :non_member | 1
    :internal | :enabled  | :enabled  | :anonymous  | 0

    :internal | :enabled  | :private  | :admin      | 1
    :internal | :enabled  | :private  | :reporter   | 1
    :internal | :enabled  | :private  | :guest      | 1
    :internal | :enabled  | :private  | :non_member | 1
    :internal | :enabled  | :private  | :anonymous  | 0

    :internal | :enabled  | :disabled | :admin      | 1
    :internal | :enabled  | :disabled | :reporter   | 1
    :internal | :enabled  | :disabled | :guest      | 1
    :internal | :enabled  | :disabled | :non_member | 1
    :internal | :enabled  | :disabled | :anonymous  | 0

    :internal | :private  | :enabled  | :admin      | 1
    :internal | :private  | :enabled  | :reporter   | 1
    :internal | :private  | :enabled  | :guest      | 1
    :internal | :private  | :enabled  | :non_member | 1
    :internal | :private  | :enabled  | :anonymous  | 0

    :internal | :private  | :private  | :admin      | 1
    :internal | :private  | :private  | :reporter   | 1
    :internal | :private  | :private  | :guest      | 1
    :internal | :private  | :private  | :non_member | 0
    :internal | :private  | :private  | :anonymous  | 0

    :internal | :private  | :disabled | :admin      | 1
    :internal | :private  | :disabled | :reporter   | 1
    :internal | :private  | :disabled | :guest      | 1
    :internal | :private  | :disabled | :non_member | 0
    :internal | :private  | :disabled | :anonymous  | 0

    :internal | :disabled | :enabled  | :admin      | 1
    :internal | :disabled | :enabled  | :reporter   | 1
    :internal | :disabled | :enabled  | :guest      | 1
    :internal | :disabled | :enabled  | :non_member | 1
    :internal | :disabled | :enabled  | :anonymous  | 0

    :internal | :disabled | :private  | :admin      | 1
    :internal | :disabled | :private  | :reporter   | 1
    :internal | :disabled | :private  | :guest      | 0
    :internal | :disabled | :private  | :non_member | 0
    :internal | :disabled | :private  | :anonymous  | 0

    :internal | :disabled | :disabled | :reporter   | 0
    :internal | :disabled | :disabled | :guest      | 0
    :internal | :disabled | :disabled | :non_member | 0
    :internal | :disabled | :disabled | :anonymous  | 0

    :private  | :private  | :private  | :admin      | 1
    :private  | :private  | :private  | :reporter   | 1
    :private  | :private  | :private  | :guest      | 1
    :private  | :private  | :private  | :non_member | 0
    :private  | :private  | :private  | :anonymous  | 0

    :private  | :private  | :disabled | :admin      | 1
    :private  | :private  | :disabled | :reporter   | 1
    :private  | :private  | :disabled | :guest      | 1
    :private  | :private  | :disabled | :non_member | 0
    :private  | :private  | :disabled | :anonymous  | 0

    :private  | :disabled | :private  | :admin      | 1
    :private  | :disabled | :private  | :reporter   | 1
    :private  | :disabled | :private  | :guest      | 0
    :private  | :disabled | :private  | :non_member | 0
    :private  | :disabled | :private  | :anonymous  | 0

    :private  | :disabled | :disabled | :reporter   | 0
    :private  | :disabled | :disabled | :guest      | 0
    :private  | :disabled | :disabled | :non_member | 0
    :private  | :disabled | :disabled | :anonymous  | 0
  end

  # :project_level, :membership, :expected_count
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
