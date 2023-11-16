# frozen_string_literal: true

RSpec.shared_context 'ProjectPolicyTable context' do
  using RSpec::Parameterized::TableSyntax

  include AdminModeHelper

  let(:pendings) { {} }
  let(:pending?) do
    pendings.include?(
      {
        project_level: project_level,
        feature_access_level: feature_access_level,
        membership: membership,
        admin_mode: admin_mode,
        expected_count: expected_count
      }
    )
  end

  # rubocop:disable Metrics/AbcSize
  # project_level, :feature_access_level, :membership, :admin_mode, :expected_count
  def permission_table_for_reporter_feature_access
    :public   | :enabled  | :admin      | true  | 1
    :public   | :enabled  | :admin      | false | 1
    :public   | :enabled  | :reporter   | nil   | 1
    :public   | :enabled  | :guest      | nil   | 1
    :public   | :enabled  | :non_member | nil   | 1
    :public   | :enabled  | :anonymous  | nil   | 1

    :public   | :private  | :admin      | true  | 1
    :public   | :private  | :admin      | false | 0
    :public   | :private  | :reporter   | nil   | 1
    :public   | :private  | :guest      | nil   | 0
    :public   | :private  | :non_member | nil   | 0
    :public   | :private  | :anonymous  | nil   | 0

    :public   | :disabled | :reporter   | nil   | 0
    :public   | :disabled | :guest      | nil   | 0
    :public   | :disabled | :non_member | nil   | 0
    :public   | :disabled | :anonymous  | nil   | 0

    :internal | :enabled  | :admin      | true  | 1
    :internal | :enabled  | :admin      | false | 1
    :internal | :enabled  | :reporter   | nil   | 1
    :internal | :enabled  | :guest      | nil   | 1
    :internal | :enabled  | :non_member | nil   | 1
    :internal | :enabled  | :anonymous  | nil   | 0

    :internal | :private  | :admin      | true  | 1
    :internal | :private  | :admin      | false | 0
    :internal | :private  | :reporter   | nil   | 1
    :internal | :private  | :guest      | nil   | 0
    :internal | :private  | :non_member | nil   | 0
    :internal | :private  | :anonymous  | nil   | 0

    :internal | :disabled | :reporter   | nil   | 0
    :internal | :disabled | :guest      | nil   | 0
    :internal | :disabled | :non_member | nil   | 0
    :internal | :disabled | :anonymous  | nil   | 0

    :private  | :private  | :admin      | true  | 1
    :private  | :private  | :admin      | false | 0
    :private  | :private  | :reporter   | nil   | 1
    :private  | :private  | :guest      | nil   | 0
    :private  | :private  | :non_member | nil   | 0
    :private  | :private  | :anonymous  | nil   | 0

    :private  | :disabled | :reporter   | nil   | 0
    :private  | :disabled | :guest      | nil   | 0
    :private  | :disabled | :non_member | nil   | 0
    :private  | :disabled | :anonymous  | nil   | 0
  end

  # group_level, :membership, :admin_mode, :expected_count
  # We need a new table because epics are at a group level only.
  def permission_table_for_epics_access
    :public   | :admin      | true  | 1
    :public   | :admin      | false | 1
    :public   | :reporter   | nil   | 1
    :public   | :guest      | nil   | 1
    :public   | :non_member | nil   | 1
    :public   | :anonymous  | nil   | 1

    :internal | :admin      | true  | 1
    :internal | :admin      | false | 1
    :internal | :reporter   | nil   | 1
    :internal | :guest      | nil   | 1
    :internal | :non_member | nil   | 1
    :internal | :anonymous  | nil   | 0

    :private  | :admin      | true  | 1
    :private  | :admin      | false | 0
    :private  | :reporter   | nil   | 1
    :private  | :guest      | nil   | 1
    :private  | :non_member | nil   | 0
    :private  | :anonymous  | nil   | 0
  end

  # project_level, :feature_access_level, :membership, :admin_mode, :expected_count
  def permission_table_for_guest_feature_access
    :public   | :enabled  | :admin      | true  | 1
    :public   | :enabled  | :admin      | false | 1
    :public   | :enabled  | :reporter   | nil   | 1
    :public   | :enabled  | :guest      | nil   | 1
    :public   | :enabled  | :non_member | nil   | 1
    :public   | :enabled  | :anonymous  | nil   | 1

    :public   | :private  | :admin      | true  | 1
    :public   | :private  | :admin      | false | 0
    :public   | :private  | :reporter   | nil   | 1
    :public   | :private  | :guest      | nil   | 1
    :public   | :private  | :non_member | nil   | 0
    :public   | :private  | :anonymous  | nil   | 0

    :public   | :disabled | :reporter   | nil   | 0
    :public   | :disabled | :guest      | nil   | 0
    :public   | :disabled | :non_member | nil   | 0
    :public   | :disabled | :anonymous  | nil   | 0

    :internal | :enabled  | :admin      | true  | 1
    :internal | :enabled  | :admin      | false | 1
    :internal | :enabled  | :reporter   | nil   | 1
    :internal | :enabled  | :guest      | nil   | 1
    :internal | :enabled  | :non_member | nil   | 1
    :internal | :enabled  | :anonymous  | nil   | 0

    :internal | :private  | :admin      | true  | 1
    :internal | :private  | :admin      | false | 0
    :internal | :private  | :reporter   | nil   | 1
    :internal | :private  | :guest      | nil   | 1
    :internal | :private  | :non_member | nil   | 0
    :internal | :private  | :anonymous  | nil   | 0

    :internal | :disabled | :reporter   | nil   | 0
    :internal | :disabled | :guest      | nil   | 0
    :internal | :disabled | :non_member | nil   | 0
    :internal | :disabled | :anonymous  | nil   | 0

    :private  | :private  | :admin      | true  | 1
    :private  | :private  | :admin      | false | 0
    :private  | :private  | :reporter   | nil   | 1
    :private  | :private  | :guest      | nil   | 1
    :private  | :private  | :non_member | nil   | 0
    :private  | :private  | :anonymous  | nil   | 0

    :private  | :disabled | :reporter   | nil   | 0
    :private  | :disabled | :guest      | nil   | 0
    :private  | :disabled | :non_member | nil   | 0
    :private  | :disabled | :anonymous  | nil   | 0
  end

  # This table is based on permission_table_for_guest_feature_access,
  # but takes into account note confidentiality. It is required on the context
  # to have one regular note and one confidential note.
  #
  # project_level, :feature_access_level, :membership, :admin_mode, :expected_count
  def permission_table_for_notes_feature_access
    :public   | :enabled  | :admin      | true  | 2
    :public   | :enabled  | :admin      | false | 1
    :public   | :enabled  | :reporter   | nil   | 2
    :public   | :enabled  | :guest      | nil   | 1
    :public   | :enabled  | :non_member | nil   | 1
    :public   | :enabled  | :anonymous  | nil   | 1

    :public   | :private  | :admin      | true  | 2
    :public   | :private  | :admin      | false | 0
    :public   | :private  | :reporter   | nil   | 2
    :public   | :private  | :guest      | nil   | 1
    :public   | :private  | :non_member | nil   | 0
    :public   | :private  | :anonymous  | nil   | 0

    :public   | :disabled | :reporter   | nil   | 0
    :public   | :disabled | :guest      | nil   | 0
    :public   | :disabled | :non_member | nil   | 0
    :public   | :disabled | :anonymous  | nil   | 0

    :internal | :enabled  | :admin      | true  | 2
    :internal | :enabled  | :admin      | false | 1
    :internal | :enabled  | :reporter   | nil   | 2
    :internal | :enabled  | :guest      | nil   | 1
    :internal | :enabled  | :non_member | nil   | 1
    :internal | :enabled  | :anonymous  | nil   | 0

    :internal | :private  | :admin      | true  | 2
    :internal | :private  | :admin      | false | 0
    :internal | :private  | :reporter   | nil   | 2
    :internal | :private  | :guest      | nil   | 1
    :internal | :private  | :non_member | nil   | 0
    :internal | :private  | :anonymous  | nil   | 0

    :internal | :disabled | :reporter   | nil   | 0
    :internal | :disabled | :guest      | nil   | 0
    :internal | :disabled | :non_member | nil   | 0
    :internal | :disabled | :anonymous  | nil   | 0

    :private  | :private  | :admin      | true  | 2
    :private  | :private  | :admin      | false | 0
    :private  | :private  | :reporter   | nil   | 2
    :private  | :private  | :guest      | nil   | 1
    :private  | :private  | :non_member | nil   | 0
    :private  | :private  | :anonymous  | nil   | 0

    :private  | :disabled | :reporter   | nil   | 0
    :private  | :disabled | :guest      | nil   | 0
    :private  | :disabled | :non_member | nil   | 0
    :private  | :disabled | :anonymous  | nil   | 0
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
  # project_level, :feature_access_level, :membership, :admin_mode, :expected_count
  def permission_table_for_guest_feature_access_and_non_private_project_only
    :public   | :enabled  | :admin      | true  | 1
    :public   | :enabled  | :admin      | false | 1
    :public   | :enabled  | :reporter   | nil   | 1
    :public   | :enabled  | :guest      | nil   | 1
    :public   | :enabled  | :non_member | nil   | 1
    :public   | :enabled  | :anonymous  | nil   | 1

    :public   | :private  | :admin      | true  | 1
    :public   | :private  | :admin      | false | 0
    :public   | :private  | :reporter   | nil   | 1
    :public   | :private  | :guest      | nil   | 1
    :public   | :private  | :non_member | nil   | 0
    :public   | :private  | :anonymous  | nil   | 0

    :public   | :disabled | :reporter   | nil   | 0
    :public   | :disabled | :guest      | nil   | 0
    :public   | :disabled | :non_member | nil   | 0
    :public   | :disabled | :anonymous  | nil   | 0

    :internal | :enabled  | :admin      | true  | 1
    :internal | :enabled  | :admin      | false | 1
    :internal | :enabled  | :reporter   | nil   | 1
    :internal | :enabled  | :guest      | nil   | 1
    :internal | :enabled  | :non_member | nil   | 1
    :internal | :enabled  | :anonymous  | nil   | 0

    :internal | :private  | :admin      | true  | 1
    :internal | :private  | :admin      | false | 0
    :internal | :private  | :reporter   | nil   | 1
    :internal | :private  | :guest      | nil   | 1
    :internal | :private  | :non_member | nil   | 0
    :internal | :private  | :anonymous  | nil   | 0

    :internal | :disabled | :reporter   | nil   | 0
    :internal | :disabled | :guest      | nil   | 0
    :internal | :disabled | :non_member | nil   | 0
    :internal | :disabled | :anonymous  | nil   | 0

    :private  | :private  | :admin      | true  | 1
    :private  | :private  | :admin      | false | 0
    :private  | :private  | :reporter   | nil   | 1
    :private  | :private  | :guest      | nil   | 0
    :private  | :private  | :non_member | nil   | 0
    :private  | :private  | :anonymous  | nil   | 0

    :private  | :disabled | :reporter   | nil   | 0
    :private  | :disabled | :guest      | nil   | 0
    :private  | :disabled | :non_member | nil   | 0
    :private  | :disabled | :anonymous  | nil   | 0
  end

  # :project_level, :issues_access_level, :merge_requests_access_level, :membership, :admin_mode, :expected_count
  def permission_table_for_milestone_access
    :public   | :enabled  | :enabled  | :admin      | true  | 1
    :public   | :enabled  | :enabled  | :admin      | false | 1
    :public   | :enabled  | :enabled  | :reporter   | nil   | 1
    :public   | :enabled  | :enabled  | :guest      | nil   | 1
    :public   | :enabled  | :enabled  | :non_member | nil   | 1
    :public   | :enabled  | :enabled  | :anonymous  | nil   | 1

    :public   | :enabled  | :private  | :admin      | true  | 1
    :public   | :enabled  | :private  | :admin      | false | 1
    :public   | :enabled  | :private  | :reporter   | nil   | 1
    :public   | :enabled  | :private  | :guest      | nil   | 1
    :public   | :enabled  | :private  | :non_member | nil   | 1
    :public   | :enabled  | :private  | :anonymous  | nil   | 1

    :public   | :enabled  | :disabled | :admin      | true  | 1
    :public   | :enabled  | :disabled | :admin      | false | 1
    :public   | :enabled  | :disabled | :reporter   | nil   | 1
    :public   | :enabled  | :disabled | :guest      | nil   | 1
    :public   | :enabled  | :disabled | :non_member | nil   | 1
    :public   | :enabled  | :disabled | :anonymous  | nil   | 1

    :public   | :private  | :enabled  | :admin      | true  | 1
    :public   | :private  | :enabled  | :admin      | false | 1
    :public   | :private  | :enabled  | :reporter   | nil   | 1
    :public   | :private  | :enabled  | :guest      | nil   | 1
    :public   | :private  | :enabled  | :non_member | nil   | 1
    :public   | :private  | :enabled  | :anonymous  | nil   | 1

    :public   | :private  | :private  | :admin      | true  | 1
    :public   | :private  | :private  | :admin      | false | 0
    :public   | :private  | :private  | :reporter   | nil   | 1
    :public   | :private  | :private  | :guest      | nil   | 1
    :public   | :private  | :private  | :non_member | nil   | 0
    :public   | :private  | :private  | :anonymous  | nil   | 0

    :public   | :private  | :disabled | :admin      | true  | 1
    :public   | :private  | :disabled | :admin      | false | 0
    :public   | :private  | :disabled | :reporter   | nil   | 1
    :public   | :private  | :disabled | :guest      | nil   | 1
    :public   | :private  | :disabled | :non_member | nil   | 0
    :public   | :private  | :disabled | :anonymous  | nil   | 0

    :public   | :disabled | :enabled  | :admin      | true  | 1
    :public   | :disabled | :enabled  | :admin      | false | 1
    :public   | :disabled | :enabled  | :reporter   | nil   | 1
    :public   | :disabled | :enabled  | :guest      | nil   | 1
    :public   | :disabled | :enabled  | :non_member | nil   | 1
    :public   | :disabled | :enabled  | :anonymous  | nil   | 1

    :public   | :disabled | :private  | :admin      | true  | 1
    :public   | :disabled | :private  | :admin      | false | 0
    :public   | :disabled | :private  | :reporter   | nil   | 1
    :public   | :disabled | :private  | :guest      | nil   | 0
    :public   | :disabled | :private  | :non_member | nil   | 0
    :public   | :disabled | :private  | :anonymous  | nil   | 0

    :public   | :disabled | :disabled | :reporter   | nil   | 0
    :public   | :disabled | :disabled | :guest      | nil   | 0
    :public   | :disabled | :disabled | :non_member | nil   | 0
    :public   | :disabled | :disabled | :anonymous  | nil   | 0

    :internal | :enabled  | :enabled  | :admin      | true  | 1
    :internal | :enabled  | :enabled  | :admin      | false | 1
    :internal | :enabled  | :enabled  | :reporter   | nil   | 1
    :internal | :enabled  | :enabled  | :guest      | nil   | 1
    :internal | :enabled  | :enabled  | :non_member | nil   | 1
    :internal | :enabled  | :enabled  | :anonymous  | nil   | 0

    :internal | :enabled  | :private  | :admin      | true  | 1
    :internal | :enabled  | :private  | :admin      | false | 1
    :internal | :enabled  | :private  | :reporter   | nil   | 1
    :internal | :enabled  | :private  | :guest      | nil   | 1
    :internal | :enabled  | :private  | :non_member | nil   | 1
    :internal | :enabled  | :private  | :anonymous  | nil   | 0

    :internal | :enabled  | :disabled | :admin      | true  | 1
    :internal | :enabled  | :disabled | :admin      | false | 1
    :internal | :enabled  | :disabled | :reporter   | nil   | 1
    :internal | :enabled  | :disabled | :guest      | nil   | 1
    :internal | :enabled  | :disabled | :non_member | nil   | 1
    :internal | :enabled  | :disabled | :anonymous  | nil   | 0

    :internal | :private  | :enabled  | :admin      | true  | 1
    :internal | :private  | :enabled  | :admin      | false | 1
    :internal | :private  | :enabled  | :reporter   | nil   | 1
    :internal | :private  | :enabled  | :guest      | nil   | 1
    :internal | :private  | :enabled  | :non_member | nil   | 1
    :internal | :private  | :enabled  | :anonymous  | nil   | 0

    :internal | :private  | :private  | :admin      | true  | 1
    :internal | :private  | :private  | :admin      | false | 0
    :internal | :private  | :private  | :reporter   | nil   | 1
    :internal | :private  | :private  | :guest      | nil   | 1
    :internal | :private  | :private  | :non_member | nil   | 0
    :internal | :private  | :private  | :anonymous  | nil   | 0

    :internal | :private  | :disabled | :admin      | true  | 1
    :internal | :private  | :disabled | :admin      | false | 0
    :internal | :private  | :disabled | :reporter   | nil   | 1
    :internal | :private  | :disabled | :guest      | nil   | 1
    :internal | :private  | :disabled | :non_member | nil   | 0
    :internal | :private  | :disabled | :anonymous  | nil   | 0

    :internal | :disabled | :enabled  | :admin      | true  | 1
    :internal | :disabled | :enabled  | :admin      | false | 1
    :internal | :disabled | :enabled  | :reporter   | nil   | 1
    :internal | :disabled | :enabled  | :guest      | nil   | 1
    :internal | :disabled | :enabled  | :non_member | nil   | 1
    :internal | :disabled | :enabled  | :anonymous  | nil   | 0

    :internal | :disabled | :private  | :admin      | true  | 1
    :internal | :disabled | :private  | :admin      | false | 0
    :internal | :disabled | :private  | :reporter   | nil   | 1
    :internal | :disabled | :private  | :guest      | nil   | 0
    :internal | :disabled | :private  | :non_member | nil   | 0
    :internal | :disabled | :private  | :anonymous  | nil   | 0

    :internal | :disabled | :disabled | :reporter   | nil   | 0
    :internal | :disabled | :disabled | :guest      | nil   | 0
    :internal | :disabled | :disabled | :non_member | nil   | 0
    :internal | :disabled | :disabled | :anonymous  | nil   | 0

    :private  | :private  | :private  | :admin      | true  | 1
    :private  | :private  | :private  | :admin      | false | 0
    :private  | :private  | :private  | :reporter   | nil   | 1
    :private  | :private  | :private  | :guest      | nil   | 1
    :private  | :private  | :private  | :non_member | nil   | 0
    :private  | :private  | :private  | :anonymous  | nil   | 0

    :private  | :private  | :disabled | :admin      | true  | 1
    :private  | :private  | :disabled | :admin      | false | 0
    :private  | :private  | :disabled | :reporter   | nil   | 1
    :private  | :private  | :disabled | :guest      | nil   | 1
    :private  | :private  | :disabled | :non_member | nil   | 0
    :private  | :private  | :disabled | :anonymous  | nil   | 0

    :private  | :disabled | :private  | :admin      | true  | 1
    :private  | :disabled | :private  | :admin      | false | 0
    :private  | :disabled | :private  | :reporter   | nil   | 1
    :private  | :disabled | :private  | :guest      | nil   | 0
    :private  | :disabled | :private  | :non_member | nil   | 0
    :private  | :disabled | :private  | :anonymous  | nil   | 0

    :private  | :disabled | :disabled | :reporter   | nil   | 0
    :private  | :disabled | :disabled | :guest      | nil   | 0
    :private  | :disabled | :disabled | :non_member | nil   | 0
    :private  | :disabled | :disabled | :anonymous  | nil   | 0
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

  # :snippet_level, :project_level, :feature_access_level, :membership, :admin_mode, :expected_count
  def permission_table_for_project_snippet_access
    :public   | :public   | :enabled  | :admin      | true  | 1
    :public   | :public   | :enabled  | :admin      | false | 1
    :public   | :public   | :enabled  | :reporter   | nil   | 1
    :public   | :public   | :enabled  | :guest      | nil   | 1
    :public   | :public   | :enabled  | :non_member | nil   | 1
    :public   | :public   | :enabled  | :anonymous  | nil   | 1

    :public   | :public   | :private  | :admin      | true  | 1
    :public   | :public   | :private  | :admin      | false | 0
    :public   | :public   | :private  | :reporter   | nil   | 1
    :public   | :public   | :private  | :guest      | nil   | 1
    :public   | :public   | :private  | :non_member | nil   | 0
    :public   | :public   | :private  | :anonymous  | nil   | 0

    :public   | :public   | :disabled | :admin      | true  | 1
    :public   | :public   | :disabled | :admin      | false | 0
    :public   | :public   | :disabled | :reporter   | nil   | 0
    :public   | :public   | :disabled | :guest      | nil   | 0
    :public   | :public   | :disabled | :non_member | nil   | 0
    :public   | :public   | :disabled | :anonymous  | nil   | 0

    :public   | :internal | :enabled  | :admin      | true  | 1
    :public   | :internal | :enabled  | :admin      | false | 1
    :public   | :internal | :enabled  | :reporter   | nil   | 1
    :public   | :internal | :enabled  | :guest      | nil   | 1
    :public   | :internal | :enabled  | :non_member | nil   | 1
    :public   | :internal | :enabled  | :anonymous  | nil   | 0

    :public   | :internal | :private  | :admin      | true  | 1
    :public   | :internal | :private  | :admin      | false | 0
    :public   | :internal | :private  | :reporter   | nil   | 1
    :public   | :internal | :private  | :guest      | nil   | 1
    :public   | :internal | :private  | :non_member | nil   | 0
    :public   | :internal | :private  | :anonymous  | nil   | 0

    :public   | :internal | :disabled | :admin      | true  | 1
    :public   | :internal | :disabled | :admin      | false | 0
    :public   | :internal | :disabled | :reporter   | nil   | 0
    :public   | :internal | :disabled | :guest      | nil   | 0
    :public   | :internal | :disabled | :non_member | nil   | 0
    :public   | :internal | :disabled | :anonymous  | nil   | 0

    :public   | :private  | :private  | :admin      | true  | 1
    :public   | :private  | :private  | :admin      | false | 0
    :public   | :private  | :private  | :reporter   | nil   | 1
    :public   | :private  | :private  | :guest      | nil   | 1
    :public   | :private  | :private  | :non_member | nil   | 0
    :public   | :private  | :private  | :anonymous  | nil   | 0

    :public   | :private  | :disabled | :reporter   | nil   | 0
    :public   | :private  | :disabled | :guest      | nil   | 0
    :public   | :private  | :disabled | :non_member | nil   | 0
    :public   | :private  | :disabled | :anonymous  | nil   | 0

    :internal | :public   | :enabled  | :admin      | true  | 1
    :internal | :public   | :enabled  | :admin      | false | 1
    :internal | :public   | :enabled  | :reporter   | nil   | 1
    :internal | :public   | :enabled  | :guest      | nil   | 1
    :internal | :public   | :enabled  | :non_member | nil   | 1
    :internal | :public   | :enabled  | :anonymous  | nil   | 0

    :internal | :public   | :private  | :admin      | true  | 1
    :internal | :public   | :private  | :admin      | false | 0
    :internal | :public   | :private  | :reporter   | nil   | 1
    :internal | :public   | :private  | :guest      | nil   | 1
    :internal | :public   | :private  | :non_member | nil   | 0
    :internal | :public   | :private  | :anonymous  | nil   | 0

    :internal | :public   | :disabled | :admin      | true  | 1
    :internal | :public   | :disabled | :admin      | false | 0
    :internal | :public   | :disabled | :reporter   | nil   | 0
    :internal | :public   | :disabled | :guest      | nil   | 0
    :internal | :public   | :disabled | :non_member | nil   | 0
    :internal | :public   | :disabled | :anonymous  | nil   | 0

    :internal | :internal | :enabled  | :admin      | true  | 1
    :internal | :internal | :enabled  | :admin      | false | 1
    :internal | :internal | :enabled  | :reporter   | nil   | 1
    :internal | :internal | :enabled  | :guest      | nil   | 1
    :internal | :internal | :enabled  | :non_member | nil   | 1
    :internal | :internal | :enabled  | :anonymous  | nil   | 0

    :internal | :internal | :private  | :admin      | true  | 1
    :internal | :internal | :private  | :admin      | false | 0
    :internal | :internal | :private  | :reporter   | nil   | 1
    :internal | :internal | :private  | :guest      | nil   | 1
    :internal | :internal | :private  | :non_member | nil   | 0
    :internal | :internal | :private  | :anonymous  | nil   | 0

    :internal | :internal | :disabled | :admin      | true  | 1
    :internal | :internal | :disabled | :admin      | false | 0
    :internal | :internal | :disabled | :reporter   | nil   | 0
    :internal | :internal | :disabled | :guest      | nil   | 0
    :internal | :internal | :disabled | :non_member | nil   | 0
    :internal | :internal | :disabled | :anonymous  | nil   | 0

    :internal | :private  | :private  | :admin      | true  | 1
    :internal | :private  | :private  | :admin      | false | 0
    :internal | :private  | :private  | :reporter   | nil   | 1
    :internal | :private  | :private  | :guest      | nil   | 1
    :internal | :private  | :private  | :non_member | nil   | 0
    :internal | :private  | :private  | :anonymous  | nil   | 0

    :internal | :private  | :disabled | :admin      | true  | 1
    :internal | :private  | :disabled | :admin      | false | 0
    :internal | :private  | :disabled | :reporter   | nil   | 0
    :internal | :private  | :disabled | :guest      | nil   | 0
    :internal | :private  | :disabled | :non_member | nil   | 0
    :internal | :private  | :disabled | :anonymous  | nil   | 0

    :private  | :public   | :enabled  | :admin      | true  | 1
    :private  | :public   | :enabled  | :admin      | false | 0
    :private  | :public   | :enabled  | :reporter   | nil   | 1
    :private  | :public   | :enabled  | :guest      | nil   | 1
    :private  | :public   | :enabled  | :non_member | nil   | 0
    :private  | :public   | :enabled  | :anonymous  | nil   | 0

    :private  | :public   | :private  | :admin      | true  | 1
    :private  | :public   | :private  | :admin      | false | 0
    :private  | :public   | :private  | :reporter   | nil   | 1
    :private  | :public   | :private  | :guest      | nil   | 1
    :private  | :public   | :private  | :non_member | nil   | 0
    :private  | :public   | :private  | :anonymous  | nil   | 0

    :private  | :public   | :disabled | :admin      | true  | 1
    :private  | :public   | :disabled | :admin      | false | 0
    :private  | :public   | :disabled | :reporter   | nil   | 0
    :private  | :public   | :disabled | :guest      | nil   | 0
    :private  | :public   | :disabled | :non_member | nil   | 0
    :private  | :public   | :disabled | :anonymous  | nil   | 0

    :private  | :internal | :enabled  | :admin      | true  | 1
    :private  | :internal | :enabled  | :admin      | false | 0
    :private  | :internal | :enabled  | :reporter   | nil   | 1
    :private  | :internal | :enabled  | :guest      | nil   | 1
    :private  | :internal | :enabled  | :non_member | nil   | 0
    :private  | :internal | :enabled  | :anonymous  | nil   | 0

    :private  | :internal | :private  | :admin      | true  | 1
    :private  | :internal | :private  | :admin      | false | 0
    :private  | :internal | :private  | :reporter   | nil   | 1
    :private  | :internal | :private  | :guest      | nil   | 1
    :private  | :internal | :private  | :non_member | nil   | 0
    :private  | :internal | :private  | :anonymous  | nil   | 0

    :private  | :internal | :disabled | :admin      | true  | 1
    :private  | :internal | :disabled | :admin      | false | 0
    :private  | :internal | :disabled | :reporter   | nil   | 0
    :private  | :internal | :disabled | :guest      | nil   | 0
    :private  | :internal | :disabled | :non_member | nil   | 0
    :private  | :internal | :disabled | :anonymous  | nil   | 0

    :private  | :private  | :private  | :admin      | true  | 1
    :private  | :private  | :private  | :admin      | false | 0
    :private  | :private  | :private  | :reporter   | nil   | 1
    :private  | :private  | :private  | :guest      | nil   | 1
    :private  | :private  | :private  | :non_member | nil   | 0
    :private  | :private  | :private  | :anonymous  | nil   | 0

    :private  | :private  | :disabled | :admin      | true  | 1
    :private  | :private  | :disabled | :admin      | false | 0
    :private  | :private  | :disabled | :reporter   | nil   | 0
    :private  | :private  | :disabled | :guest      | nil   | 0
    :private  | :private  | :disabled | :non_member | nil   | 0
    :private  | :private  | :disabled | :anonymous  | nil   | 0
  end

  # :snippet_level, :membership, :expected_count
  def permission_table_for_personal_snippet_access
    :public   | :admin      | true  | 1
    :public   | :admin      | false | 1
    :public   | :author     | nil   | 1
    :public   | :non_member | nil   | 1
    :public   | :anonymous  | nil   | 1

    :internal | :admin      | true  | 1
    :internal | :admin      | false | 1
    :internal | :author     | nil   | 1
    :internal | :non_member | nil   | 1
    :internal | :anonymous  | nil   | 0

    :private  | :admin      | true  | 1
    :private  | :admin      | false | 0
    :private  | :author     | nil   | 1
    :private  | :non_member | nil   | 0
    :private  | :anonymous  | nil   | 0
  end

  # Based on the permission_table_for_reporter_feature_access table, but for issue
  # features where public and internal projects with issues enabled only allow
  # access to reporters and above (excluding admins if admin mode is disabled)
  #
  # project_level, :feature_access_level, :membership, :admin_mode, :expected_count
  def permission_table_for_reporter_issue_access
    :public   | :enabled  | :admin      | true  | 1
    :public   | :enabled  | :admin      | false | 0
    :public   | :enabled  | :reporter   | nil   | 1
    :public   | :enabled  | :guest      | nil   | 0
    :public   | :enabled  | :non_member | nil   | 0
    :public   | :enabled  | :anonymous  | nil   | 0

    :public   | :private  | :admin      | true  | 1
    :public   | :private  | :admin      | false | 0
    :public   | :private  | :reporter   | nil   | 1
    :public   | :private  | :guest      | nil   | 0
    :public   | :private  | :non_member | nil   | 0
    :public   | :private  | :anonymous  | nil   | 0

    :public   | :disabled | :reporter   | nil   | 0
    :public   | :disabled | :guest      | nil   | 0
    :public   | :disabled | :non_member | nil   | 0
    :public   | :disabled | :anonymous  | nil   | 0

    :internal | :enabled  | :admin      | true  | 1
    :internal | :enabled  | :admin      | false | 0
    :internal | :enabled  | :reporter   | nil   | 1
    :internal | :enabled  | :guest      | nil   | 0
    :internal | :enabled  | :non_member | nil   | 0
    :internal | :enabled  | :anonymous  | nil   | 0

    :internal | :private  | :admin      | true  | 1
    :internal | :private  | :admin      | false | 0
    :internal | :private  | :reporter   | nil   | 1
    :internal | :private  | :guest      | nil   | 0
    :internal | :private  | :non_member | nil   | 0
    :internal | :private  | :anonymous  | nil   | 0

    :internal | :disabled | :reporter   | nil   | 0
    :internal | :disabled | :guest      | nil   | 0
    :internal | :disabled | :non_member | nil   | 0
    :internal | :disabled | :anonymous  | nil   | 0

    :private  | :private  | :admin      | true  | 1
    :private  | :private  | :admin      | false | 0
    :private  | :private  | :reporter   | nil   | 1
    :private  | :private  | :guest      | nil   | 0
    :private  | :private  | :non_member | nil   | 0
    :private  | :private  | :anonymous  | nil   | 0

    :private  | :disabled | :reporter   | nil   | 0
    :private  | :disabled | :guest      | nil   | 0
    :private  | :disabled | :non_member | nil   | 0
    :private  | :disabled | :anonymous  | nil   | 0
  end
  # rubocop:enable Metrics/AbcSize
end
