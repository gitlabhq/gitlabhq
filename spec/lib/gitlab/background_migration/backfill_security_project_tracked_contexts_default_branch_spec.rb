# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSecurityProjectTrackedContextsDefaultBranch,
  feature_category: :vulnerability_management do
  let(:tracked_contexts) { table(:security_project_tracked_contexts, database: :sec) }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { described_class::Project }
  let(:identifiers) { table(:vulnerability_identifiers, database: :sec) }
  let(:scanners) { table(:vulnerability_scanners, database: :sec) }
  let(:findings) { table(:vulnerability_occurrences, database: :sec) }
  let(:vulnerabilities) { table(:vulnerabilities, database: :sec) }
  let(:sbom_components) { table(:sbom_components, database: :sec) }
  let(:sbom_occurrences) { table(:sbom_occurrences, database: :sec) }
  let(:user) { create(:user) } # rubocop:disable RSpec/FactoriesInMigrationSpecs -- Need an instance of the model
  let(:now) { Time.zone.now }
  let(:storage_version) { 0 }

  let!(:project_with_default_branch) do
    create_project(path: 'project-with-default-branch', default_branch: 'master', with_vulnerabilities: true)
  end

  let!(:project_with_other_default_branch) do
    create_project(path: 'project-with-main-branch', default_branch: 'main', with_vulnerabilities: true)
  end

  let!(:project_with_dependencies) do
    create_project(path: 'project-with-dependencies', default_branch: 'main', with_dependencies: true)
  end

  let!(:project_with_empty_repository) { create_project(path: 'project-with-empty-repo', with_vulnerabilities: true) }
  let!(:project_without_vulnerabilities) do
    create_project(path: 'project-with-no-vulnerabilities', default_branch: 'master')
  end

  before do
    allow(Gitlab::CurrentSettings).to receive(:default_branch_name).and_return('default')
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: Project.minimum(:id),
      end_id: Project.maximum(:id),
      batch_table: :projects,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  shared_examples 'a successful migration' do
    it 'creates security_project_tracked_contexts records for all projects with default branches' do
      expect { perform_migration }.to change { tracked_contexts.count }.by(5)

      expect(find_context(project_with_default_branch)).to have_attributes(
        project_id: project_with_default_branch.id,
        context_name: 'master',
        context_type: described_class::SecurityProjectTrackedContext.context_types[:branch],
        state: described_class::SecurityProjectTrackedContext::STATES[:tracked],
        is_default: true
      )

      expect(find_context(project_with_other_default_branch)).to have_attributes(
        project_id: project_with_other_default_branch.id,
        context_name: 'main',
        context_type: described_class::SecurityProjectTrackedContext.context_types[:branch],
        state: described_class::SecurityProjectTrackedContext::STATES[:tracked],
        is_default: true
      )

      expect(find_context(project_with_dependencies)).to have_attributes(
        project_id: project_with_dependencies.id,
        context_name: 'main',
        context_type: described_class::SecurityProjectTrackedContext.context_types[:branch],
        state: described_class::SecurityProjectTrackedContext::STATES[:tracked],
        is_default: true
      )

      expect(find_context(project_with_empty_repository)).to have_attributes(
        project_id: project_with_empty_repository.id,
        context_name: 'main',
        context_type: described_class::SecurityProjectTrackedContext.context_types[:branch],
        state: described_class::SecurityProjectTrackedContext::STATES[:tracked],
        is_default: true
      )

      expect(find_context(project_without_vulnerabilities)).to have_attributes(
        project_id: project_without_vulnerabilities.id,
        context_name: 'master',
        context_type: described_class::SecurityProjectTrackedContext.context_types[:branch],
        state: described_class::SecurityProjectTrackedContext::STATES[:tracked],
        is_default: true
      )
    end
  end

  it_behaves_like 'a successful migration'

  context 'when repository is using hashed storage' do
    let(:storage_version) { 1 }

    it_behaves_like 'a successful migration'
  end

  it 'handles conflicts gracefully when record already exists' do
    # Pre-create a record
    tracked_contexts.create!(
      project_id: project_with_default_branch.id,
      context_name: 'master',
      context_type: described_class::SecurityProjectTrackedContext.context_types[:branch],
      state: described_class::SecurityProjectTrackedContext::STATES[:untracked],
      is_default: false
    )

    expect { perform_migration }.to change { tracked_contexts.count }.by(4)

    # Verify the existing record was not modified
    context_record = tracked_contexts.find_by(
      project_id: project_with_default_branch.id
    )
    expect(context_record.state).to eq(1) # still untracked
    expect(context_record.is_default).to be_falsey
  end

  context 'when there are no projects in the batch' do
    before do
      Project.delete_all
    end

    it 'does not create any records' do
      expect { perform_migration }.not_to change { tracked_contexts.count }
    end
  end

  def create_project(default_branch: nil, with_vulnerabilities: false, with_dependencies: false, **attributes)
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

    create_vulnerability(project) if with_vulnerabilities
    create_sbom_occurrence(project) if with_dependencies
    create_repo(project, default_branch) if default_branch

    project
  end

  def create_vulnerability(project)
    primary_identifier = identifiers.create!(
      created_at: now,
      updated_at: now,
      project_id: project.id,
      fingerprint: '0',
      external_type: 'CWE',
      external_id: 'CWE-1',
      name: 'Injection'
    )

    scanner = scanners.create!(
      created_at: now,
      updated_at: now,
      project_id: project.id,
      external_id: 'semgrep',
      name: 'Semgrep'
    )

    finding = findings.create!(
      created_at: now,
      updated_at: now,
      uuid: SecureRandom.uuid,
      severity: 1,
      report_type: 1,
      project_id: project.id,
      scanner_id: scanner.id,
      primary_identifier_id: primary_identifier.id,
      location_fingerprint: '0',
      name: 'Test vulnerability',
      metadata_version: '1'
    )

    vulnerabilities.create!(
      project_id: project.id,
      finding_id: finding.id,
      author_id: user.id,
      created_at: now,
      updated_at: now,
      title: 'Test vulnerability',
      severity: 1,
      report_type: 1
    )
  end

  def create_sbom_occurrence(project)
    component = sbom_components.create!(
      created_at: now,
      updated_at: now,
      component_type: 0,
      name: 'rails',
      organization_id: project.organization_id
    )

    sbom_occurrences.create!(
      created_at: now,
      updated_at: now,
      project_id: project.id,
      commit_sha: '0' * 40,
      component_id: component.id,
      uuid: SecureRandom.uuid
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

  def find_context(project)
    tracked_contexts.find_by(
      project_id: project.id
    )
  end
end
