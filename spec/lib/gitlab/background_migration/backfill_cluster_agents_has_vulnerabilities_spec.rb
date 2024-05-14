# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillClusterAgentsHasVulnerabilities, :migration,
  feature_category: :vulnerability_management do
  let(:migration) do
    described_class.new(
      start_id: 1, end_id: 10,
      batch_table: table_name, batch_column: batch_column,
      sub_batch_size: sub_batch_size, pause_ms: pause_ms,
      connection: ApplicationRecord.connection
    )
  end

  let(:users_table) { table(:users) }
  let(:vulnerability_identifiers_table) { table(:vulnerability_identifiers) }
  let(:vulnerability_occurrences_table) { table(:vulnerability_occurrences) }
  let(:vulnerability_reads_table) { table(:vulnerability_reads) }
  let(:vulnerability_scanners_table) { table(:vulnerability_scanners) }
  let(:vulnerabilities_table) { table(:vulnerabilities) }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:cluster_agents_table) { table(:cluster_agents) }

  let(:table_name) { 'cluster_agents' }
  let(:batch_column) { :id }
  let(:sub_batch_size) { 100 }
  let(:pause_ms) { 0 }

  subject(:perform_migration) { migration.perform }

  before do
    users_table.create!(id: 1, name: 'John Doe', email: 'test@example.com', projects_limit: 5)

    namespaces_table.create!(id: 1, name: 'Namespace 1', path: 'namespace-1')
    namespaces_table.create!(id: 2, name: 'Namespace 2', path: 'namespace-2')
    namespaces_table.create!(id: 3, name: 'Namespace 3', path: 'namespace-3')

    projects_table.create!(id: 1, namespace_id: 1, name: 'Project 1', path: 'project-1', project_namespace_id: 1)
    projects_table.create!(id: 2, namespace_id: 2, name: 'Project 2', path: 'project-2', project_namespace_id: 2)
    projects_table.create!(id: 3, namespace_id: 2, name: 'Project 3', path: 'project-3', project_namespace_id: 3)

    cluster_agents_table.create!(id: 1, name: 'Agent 1', project_id: 1)
    cluster_agents_table.create!(id: 2, name: 'Agent 2', project_id: 2)
    cluster_agents_table.create!(id: 3, name: 'Agent 3', project_id: 1)
    cluster_agents_table.create!(id: 4, name: 'Agent 4', project_id: 1)
    cluster_agents_table.create!(id: 5, name: 'Agent 5', project_id: 1)
    cluster_agents_table.create!(id: 6, name: 'Agent 6', project_id: 1)
    cluster_agents_table.create!(id: 7, name: 'Agent 7', project_id: 3)
    cluster_agents_table.create!(id: 8, name: 'Agent 8', project_id: 1)
    cluster_agents_table.create!(id: 9, name: 'Agent 9', project_id: 1)
    cluster_agents_table.create!(id: 10, name: 'Agent 10', project_id: 3)
    cluster_agents_table.create!(id: 11, name: 'Agent 11', project_id: 1)

    vulnerability_scanners_table.create!(id: 1, project_id: 1, external_id: 'starboard', name: 'Starboard')
    vulnerability_scanners_table.create!(id: 2, project_id: 2, external_id: 'starboard', name: 'Starboard')
    vulnerability_scanners_table.create!(id: 3, project_id: 3, external_id: 'starboard', name: 'Starboard')

    add_vulnerability_read!(1, project_id: 1, cluster_agent_id: 1, report_type: 7)
    add_vulnerability_read!(2, project_id: 1, cluster_agent_id: nil, report_type: 7)
    add_vulnerability_read!(3, project_id: 1, cluster_agent_id: 3, report_type: 7)
    add_vulnerability_read!(4, project_id: 1, cluster_agent_id: nil, report_type: 7)
    add_vulnerability_read!(5, project_id: 2, cluster_agent_id: 5, report_type: 5)
    add_vulnerability_read!(7, project_id: 2, cluster_agent_id: 7, report_type: 7)
    add_vulnerability_read!(9, project_id: 3, cluster_agent_id: 9, report_type: 7)
    add_vulnerability_read!(10, project_id: 1, cluster_agent_id: 10, report_type: 7)
    add_vulnerability_read!(11, project_id: 2, cluster_agent_id: 11, report_type: 7)
  end

  it 'backfills `has_vulnerabilities` for the selected records', :aggregate_failures do
    queries = ActiveRecord::QueryRecorder.new do
      perform_migration
    end

    expect(queries.count).to eq(3)
    expect(cluster_agents_table.where(has_vulnerabilities: true).count).to eq 2
    expect(cluster_agents_table.where(has_vulnerabilities: true).pluck(:id)).to match_array([1, 3])
  end

  it 'tracks timings of queries' do
    expect(migration.batch_metrics.timings).to be_empty

    expect { perform_migration }.to change { migration.batch_metrics.timings }
  end

  private

  def add_vulnerability_read!(id, project_id:, cluster_agent_id:, report_type:)
    identifier = vulnerability_identifiers_table.create!(project_id: project_id, external_type: 'uuid-v5',
      external_id: 'uuid-v5', fingerprint: OpenSSL::Digest.hexdigest('SHA256', SecureRandom.uuid),
      name: "Identifier for UUIDv5 #{project_id} #{cluster_agent_id}")

    finding = vulnerability_occurrences_table.create!(
      project_id: project_id, scanner_id: project_id,
      primary_identifier_id: identifier.id, name: 'test', severity: 4, confidence: 4, report_type: 0,
      uuid: SecureRandom.uuid, project_fingerprint: '123qweasdzxc',
      location_fingerprint: 'test', metadata_version: 'test',
      raw_metadata: "")

    vulnerabilities_table.create!(
      id: id,
      project_id: project_id,
      author_id: 1,
      title: "Vulnerability #{id}",
      severity: 5,
      confidence: 5,
      report_type: report_type,
      finding_id: finding.id
    )

    vulnerability_reads_table.create!(
      id: id,
      uuid: SecureRandom.uuid,
      severity: 5,
      state: 1,
      vulnerability_id: id,
      scanner_id: project_id,
      casted_cluster_agent_id: cluster_agent_id,
      project_id: project_id,
      report_type: report_type
    )
  end
end
