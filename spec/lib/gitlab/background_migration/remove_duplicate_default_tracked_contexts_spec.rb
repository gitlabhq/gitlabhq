# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveDuplicateDefaultTrackedContexts,
  feature_category: :vulnerability_management do
  let(:tracked_contexts) { table(:security_project_tracked_contexts, database: :sec) }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { described_class::Project }
  let(:vulnerability_occurrences) { table(:vulnerability_occurrences, database: :sec) }
  let(:vulnerability_reads) { table(:vulnerability_reads, database: :sec) }
  let(:vulnerability_statistics) { table(:vulnerability_statistics, database: :sec) }
  let(:vulnerability_historical_statistics) { table(:vulnerability_historical_statistics, database: :sec) }
  let(:sbom_components) { table(:sbom_components, database: :sec) }
  let(:sbom_occurrences) { table(:sbom_occurrences, database: :sec) }
  let(:sbom_occurrence_refs) { table(:sbom_occurrence_refs, database: :sec) }
  let(:identifiers) { table(:vulnerability_identifiers, database: :sec) }
  let(:scanners) { table(:vulnerability_scanners, database: :sec) }
  let(:vulnerabilities) { table(:vulnerabilities, database: :sec) }
  let(:user) { create(:user) } # rubocop:disable RSpec/FactoriesInMigrationSpecs -- Need an instance of the model
  let(:now) { Time.zone.now }
  let(:storage_version) { 0 }
  let(:start_id) { projects.minimum(:id) }
  let(:end_id) { projects.maximum(:id) }

  before do
    allow(Gitlab::CurrentSettings).to receive(:default_branch_name).and_return('default')
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :projects,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  shared_examples 'a successful migration' do
    it "deletes the invalid tracked context and migrates associated records to the valid one",
      :aggregate_failures do
      expect { perform_migration }
        .to change { tracked_contexts.count }.by(-1)
        .and change { sbom_occurrence_refs.count }.by(-1)
        .and not_change { vulnerability_occurrences.count }
        .and not_change { vulnerability_reads.count }
        .and not_change { vulnerability_statistics.count }
        .and not_change { vulnerability_historical_statistics.count }

      expect(tracked_contexts.pluck(:id)).to contain_exactly(valid_tracked_context.id)

      expect(sbom_occurrence_refs.pluck(:id)).to contain_exactly(valid_sbom_occurrence_ref.id)
      expect(vulnerability_occurrences.pluck(:security_project_tracked_context_id))
        .to all(eq(valid_tracked_context.id))
      expect(vulnerability_reads.pluck(:security_project_tracked_context_id))
        .to all(eq(valid_tracked_context.id))
      expect(vulnerability_statistics.pluck(:security_project_tracked_context_id))
        .to all(eq(valid_tracked_context.id))
      expect(vulnerability_historical_statistics.pluck(:security_project_tracked_context_id))
        .to all(eq(valid_tracked_context.id))
    end
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers -- BBM deals with lot of tables
  # and its simpler to verify all of the changes at once.
  describe '#perform' do
    context "with a project with duplicate default contexts" do
      let!(:project) do
        create_project(path: "project-with-multiple-default-contexts", default_branch: "main")
      end

      let!(:valid_tracked_context) do
        create_tracked_context(project.id, "main", is_default: true)
      end

      let!(:invalid_tracked_context) do
        create_tracked_context(project.id, "old-default", is_default: true)
      end

      let!(:valid_vulnerability_occurrence) do
        create_vulnerability_occurrence(project.id, valid_tracked_context.id)
      end

      let!(:invalid_vulnerability_occurrence) do
        create_vulnerability_occurrence(project.id, invalid_tracked_context.id)
      end

      let!(:valid_vulnerability_read) do
        create_vulnerability_read(project.id, valid_tracked_context.id, valid_vulnerability_occurrence)
      end

      let!(:invalid_vulnerability_read) do
        create_vulnerability_read(project.id, invalid_tracked_context.id, invalid_vulnerability_occurrence)
      end

      let!(:invalid_vulnerability_statistic) do
        create_vulnerability_statistic(project, invalid_tracked_context.id)
      end

      let!(:invalid_vulnerability_historical_statistic) do
        create_vulnerability_historical_statistic(project.id, invalid_tracked_context.id)
      end

      let!(:valid_sbom_occurrence_ref) do
        create_sbom_occurrence_ref(project.id, valid_tracked_context.id)
      end

      let!(:invalid_sbom_occurrence_ref) do
        create_sbom_occurrence_ref(project.id, invalid_tracked_context.id)
      end

      it_behaves_like 'a successful migration'

      context "with project using hashed storage" do
        let(:storage_version) { 1 }

        it_behaves_like 'a successful migration'
      end
    end

    context 'with multiple projects with duplicate default contexts in the same batch' do
      let!(:project_a) do
        create_project(path: "project-a", default_branch: "main")
      end

      let!(:project_b) do
        create_project(path: "project-b", default_branch: "develop")
      end

      let!(:valid_context_a) do
        create_tracked_context(project_a.id, "main", is_default: true)
      end

      let!(:invalid_context_a) do
        create_tracked_context(project_a.id, "old-default-a", is_default: true)
      end

      let!(:valid_context_b) do
        create_tracked_context(project_b.id, "develop", is_default: true)
      end

      let!(:invalid_context_b) do
        create_tracked_context(project_b.id, "old-default-b", is_default: true)
      end

      let!(:occurrence_a) do
        create_vulnerability_occurrence(project_a.id, invalid_context_a.id)
      end

      let!(:occurrence_b) do
        create_vulnerability_occurrence(project_b.id, invalid_context_b.id)
      end

      let!(:read_a) do
        create_vulnerability_read(project_a.id, invalid_context_a.id, occurrence_a)
      end

      let!(:read_b) do
        create_vulnerability_read(project_b.id, invalid_context_b.id, occurrence_b)
      end

      let!(:statistic_a) do
        create_vulnerability_statistic(project_a, invalid_context_a.id)
      end

      let!(:statistic_b) do
        create_vulnerability_statistic(project_b, invalid_context_b.id)
      end

      let!(:historical_statistic_a) do
        create_vulnerability_historical_statistic(project_a.id, invalid_context_a.id)
      end

      let!(:historical_statistic_b) do
        create_vulnerability_historical_statistic(project_b.id, invalid_context_b.id)
      end

      let!(:valid_sbom_ref_a) do
        create_sbom_occurrence_ref(project_a.id, valid_context_a.id)
      end

      let!(:invalid_sbom_ref_a) do
        create_sbom_occurrence_ref(project_a.id, invalid_context_a.id)
      end

      let!(:valid_sbom_ref_b) do
        create_sbom_occurrence_ref(project_b.id, valid_context_b.id)
      end

      let!(:invalid_sbom_ref_b) do
        create_sbom_occurrence_ref(project_b.id, invalid_context_b.id)
      end

      it 'cleans up each project independently without cross-contamination', :aggregate_failures do
        expect { perform_migration }
          .to change { tracked_contexts.count }.by(-2)
          .and change { sbom_occurrence_refs.count }.by(-2)
          .and not_change { vulnerability_occurrences.count }
          .and not_change { vulnerability_reads.count }
          .and not_change { vulnerability_statistics.count }
          .and not_change { vulnerability_historical_statistics.count }

        expect(tracked_contexts.pluck(:id)).to contain_exactly(valid_context_a.id, valid_context_b.id)

        expect(sbom_occurrence_refs.pluck(:id)).to contain_exactly(valid_sbom_ref_a.id, valid_sbom_ref_b.id)

        expect(vulnerability_occurrences.find_by(id: occurrence_a.id).security_project_tracked_context_id)
          .to eq(valid_context_a.id)
        expect(vulnerability_occurrences.find_by(id: occurrence_b.id).security_project_tracked_context_id)
          .to eq(valid_context_b.id)

        expect(vulnerability_reads.find_by(id: read_a.id).security_project_tracked_context_id)
          .to eq(valid_context_a.id)
        expect(vulnerability_reads.find_by(id: read_b.id).security_project_tracked_context_id)
          .to eq(valid_context_b.id)

        expect(vulnerability_statistics.find_by(project_id: project_a.id).security_project_tracked_context_id)
          .to eq(valid_context_a.id)
        expect(vulnerability_statistics.find_by(project_id: project_b.id).security_project_tracked_context_id)
          .to eq(valid_context_b.id)

        project_a_hist = vulnerability_historical_statistics.find_by(project_id: project_a.id)
        expect(project_a_hist.security_project_tracked_context_id).to eq(valid_context_a.id)
        project_b_hist = vulnerability_historical_statistics.find_by(project_id: project_b.id)
        expect(project_b_hist.security_project_tracked_context_id).to eq(valid_context_b.id)
      end
    end

    context 'when there is an exception' do
      let!(:project) do
        create_project(path: "project-with-multiple-default-contexts", default_branch: "main")
      end

      let!(:valid_tracked_context) do
        create_tracked_context(project.id, "main", is_default: true)
      end

      let!(:invalid_tracked_context) do
        create_tracked_context(project.id, "old-default", is_default: true)
      end

      it 'logs the exception and re-raises it' do
        relation = described_class::SecurityProjectTrackedContext.none
        allow(relation).to receive(:delete_all).and_raise(ActiveRecord::QueryCanceled.new("query timed out"))
        allow(described_class::SecurityProjectTrackedContext).to receive(:id_in).and_return(relation)

        expect(::Gitlab::BackgroundMigration::Logger).to receive(:warn)

        expect { perform_migration }.to raise_error(ActiveRecord::QueryCanceled)
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  private

  def create_project(default_branch: nil, **attributes)
    attributes[:name] ||= attributes[:path]

    organization = organizations.create!(
      name: attributes[:name],
      path: attributes[:path]
    )

    namespace = namespaces.create!(
      name: attributes[:name],
      path: attributes[:path],
      organization_id: organization.id
    )

    project = projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id,
      storage_version: storage_version,
      **attributes
    )

    create_repo(project, default_branch) if default_branch

    project
  end

  def create_tracked_context(project_id, context_name, is_default: false)
    tracked_contexts.create!(
      project_id: project_id,
      context_name: context_name,
      context_type: 1, # branch
      state: 2, # tracked
      is_default: is_default
    )
  end

  def create_vulnerability_occurrence(project_id, tracked_context_id)
    primary_identifier = identifiers.create!(
      created_at: now,
      updated_at: now,
      project_id: project_id,
      fingerprint: SecureRandom.hex(8),
      external_type: 'CWE',
      external_id: 'CWE-1',
      name: 'Injection'
    )

    scanner = scanners.create!(
      created_at: now,
      updated_at: now,
      project_id: project_id,
      external_id: SecureRandom.hex(4),
      name: 'Semgrep'
    )

    vulnerability_occurrences.create!(
      created_at: now,
      updated_at: now,
      uuid: SecureRandom.uuid,
      severity: 1,
      report_type: 1,
      project_id: project_id,
      scanner_id: scanner.id,
      primary_identifier_id: primary_identifier.id,
      location_fingerprint: SecureRandom.hex(8),
      name: 'Test vulnerability',
      metadata_version: '1',
      security_project_tracked_context_id: tracked_context_id
    )
  end

  def create_vulnerability_read(project_id, tracked_context_id, vulnerability_occurrence)
    vulnerability = vulnerabilities.create!(
      project_id: project_id,
      finding_id: vulnerability_occurrence.id,
      author_id: user.id,
      created_at: now,
      updated_at: now,
      title: 'Test vulnerability',
      severity: 1,
      report_type: 1
    )

    vulnerability_reads.create!(
      vulnerability_id: vulnerability.id,
      project_id: vulnerability.project_id,
      scanner_id: vulnerability_occurrence.scanner_id,
      report_type: vulnerability.report_type,
      severity: vulnerability.severity,
      state: vulnerability.state,
      uuid: vulnerability_occurrence.uuid,
      security_project_tracked_context_id: tracked_context_id
    )
  end

  def create_vulnerability_statistic(project, security_project_tracked_context_id)
    namespace = namespaces.find(project.namespace_id)

    vulnerability_statistics.create!(
      project_id: project.id,
      security_project_tracked_context_id: security_project_tracked_context_id,
      total: 0,
      critical: 0,
      high: 0,
      medium: 0,
      low: 0,
      unknown: 0,
      info: 0,
      letter_grade: 0,
      created_at: Time.current,
      traversal_ids: [namespace.id],
      updated_at: Time.current
    )
  end

  def create_vulnerability_historical_statistic(project_id, security_project_tracked_context_id)
    vulnerability_historical_statistics.create!(
      project_id: project_id,
      total: 1,
      critical: 0,
      high: 0,
      medium: 0,
      low: 0,
      unknown: 0,
      info: 0,
      letter_grade: 0,
      created_at: now,
      updated_at: now,
      date: Time.zone.today,
      security_project_tracked_context_id: security_project_tracked_context_id
    )
  end

  def create_sbom_occurrence_ref(project_id, tracked_context_id)
    component = sbom_components.create!(
      name: "component-#{SecureRandom.hex(4)}",
      component_type: 0,
      organization_id: 1,
      created_at: now,
      updated_at: now
    )

    occurrence = sbom_occurrences.create!(
      project_id: project_id,
      component_id: component.id,
      commit_sha: SecureRandom.hex(20),
      uuid: SecureRandom.uuid,
      created_at: now,
      updated_at: now
    )

    sbom_occurrence_refs.create!(
      project_id: project_id,
      sbom_occurrence_id: occurrence.id,
      security_project_tracked_context_id: tracked_context_id,
      commit_sha: SecureRandom.hex(20)
    )
  end

  def create_repo(project, default_branch)
    return if project.repository.exists?

    project.create_repository(default_branch)
    project.repository.create_file(user, 'README.md', '# Test readme',
      **file_params.merge(branch_name: default_branch))
  end

  def file_params
    {
      message: 'Initial commit',
      author_email: user.email,
      author_name: user.name
    }
  end
end
