# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteSecurityFindingsWithoutUuid do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:ci_pipelines) { table(:ci_pipelines) }
  let(:ci_builds) { table(:ci_builds) }
  let(:ci_artifacts) { table(:ci_job_artifacts) }
  let(:scanners) { table(:vulnerability_scanners) }
  let(:security_scans) { table(:security_scans) }
  let(:security_findings) { table(:security_findings) }
  let(:sast_file_type) { 5 }
  let(:sast_scan_type) { 1 }

  let(:user) { users.create!(email: 'test@gitlab.com', projects_limit: 5) }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { projects.create!(namespace_id: namespace.id, name: 'foo') }
  let(:ci_pipeline) { ci_pipelines.create!(project_id: project.id, ref: 'master', sha: 'adf43c3a', status: 'success') }
  let(:ci_build) { ci_builds.create!(commit_id: ci_pipeline.id, retried: false, type: 'Ci::Build') }
  let(:ci_artifact) { ci_artifacts.create!(project_id: project.id, job_id: ci_build.id, file_type: sast_file_type, file_format: 1) }
  let(:scanner) { scanners.create!(project_id: project.id, external_id: 'bandit', name: 'Bandit') }
  let(:security_scan) { security_scans.create!(build_id: ci_build.id, scan_type: sast_scan_type) }

  let!(:finding_1) { security_findings.create!(scan_id: security_scan.id, scanner_id: scanner.id, severity: 0, confidence: 0, project_fingerprint: Digest::SHA1.hexdigest(SecureRandom.uuid)) }
  let!(:finding_2) { security_findings.create!(scan_id: security_scan.id, scanner_id: scanner.id, severity: 0, confidence: 0, project_fingerprint: Digest::SHA1.hexdigest(SecureRandom.uuid), uuid: SecureRandom.uuid) }

  it 'successfully runs and does not schedule any job' do
    expect { migrate! }.to change { described_class::SecurityFinding.count }.by(-1)
                       .and change { described_class::SecurityFinding.where(id: finding_1) }
  end
end
