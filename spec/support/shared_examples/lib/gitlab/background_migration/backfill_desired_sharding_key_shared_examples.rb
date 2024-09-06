# frozen_string_literal: true

RSpec.shared_examples 'desired sharding key backfill job' do
  let(:known_cross_joins) do
    {
      sbom_occurrences_vulnerabilities: {
        sbom_occurrences: 'https://gitlab.com/groups/gitlab-org/-/epics/14116#identified-cross-joins'
      },
      vulnerability_occurrence_identifiers: {
        vulnerability_occurrences: 'https://gitlab.com/gitlab-org/gitlab/-/issues/480354'
      },
      vulnerability_external_issue_links: {
        vulnerabilities: 'https://gitlab.com/gitlab-org/gitlab/-/issues/480354'
      },
      vulnerability_occurrence_pipelines: {
        vulnerability_occurrences: 'https://gitlab.com/gitlab-org/gitlab/-/issues/480354'
      },
      vulnerability_merge_request_links: {
        vulnerabilities: 'https://gitlab.com/gitlab-org/gitlab/-/issues/475058'
      },
      vulnerability_finding_evidences: {
        vulnerability_occurrences: 'https://gitlab.com/gitlab-org/gitlab/-/issues/480354'
      },
      vulnerability_finding_links: {
        vulnerability_occurrences: 'https://gitlab.com/gitlab-org/gitlab/-/issues/480354'
      },
      vulnerability_finding_signatures: {
        vulnerability_occurrences: 'https://gitlab.com/gitlab-org/gitlab/-/issues/480354'
      },
      vulnerability_flags: {
        vulnerability_occurrences: 'https://gitlab.com/gitlab-org/gitlab/-/issues/480354'
      },
      dast_site_validations: {
        dast_site_tokens: 'https://gitlab.com/gitlab-org/gitlab/-/issues/474985'
      },
      dast_site_profile_secret_variables: {
        dast_site_profiles: 'https://gitlab.com/gitlab-org/gitlab/-/issues/480014'
      },
      dast_site_profiles_builds: {
        dast_site_profiles: 'https://gitlab.com/gitlab-org/gitlab/-/issues/480014'
      },
      dast_pre_scan_verifications: {
        dast_profiles: 'https://gitlab.com/gitlab-org/gitlab/-/issues/480014'
      }
    }
  end

  let(:batch_column) { :id }
  let!(:connection) { table(batch_table).connection }
  let!(:starting_id) { table(batch_table).pluck(batch_column).min }
  let!(:end_id) { table(batch_table).pluck(batch_column).max }
  let(:job_arguments) do
    args = [
      backfill_column,
      backfill_via_table,
      backfill_via_column,
      backfill_via_foreign_key
    ]
    args << partition_column if defined?(partition_column)
    args
  end

  let!(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: batch_table,
      batch_column: batch_column,
      sub_batch_size: 10,
      pause_ms: 2,
      connection: connection,
      job_arguments: job_arguments
    )
  end

  it 'performs without error' do
    expect { migration.perform }.not_to raise_error
  end

  it 'constructs a valid query' do
    query = migration.construct_query(sub_batch: table(batch_table).all)

    if defined?(partition_column)
      expect(query).to include("AND #{backfill_via_table}.#{partition_column} = #{batch_table}.#{partition_column}")
    end

    if known_cross_joins.dig(batch_table, backfill_via_table).present?
      ::Gitlab::Database.allow_cross_joins_across_databases(
        url: known_cross_joins[batch_table][backfill_via_table]
      ) do
        expect { connection.execute(query) }.not_to raise_error
      end
    else
      expect { connection.execute(query) }.not_to raise_error
    end
  end
end
