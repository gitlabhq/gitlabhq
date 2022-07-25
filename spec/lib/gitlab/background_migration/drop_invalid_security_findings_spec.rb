# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DropInvalidSecurityFindings, :suppress_gitlab_schemas_validate_connection,
               schema: 20211108211434 do
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user', type: Namespaces::UserNamespace.sti_name) }
  let(:project) { table(:projects).create!(namespace_id: namespace.id) }

  let(:pipelines) { table(:ci_pipelines) }
  let!(:pipeline) { pipelines.create!(project_id: project.id) }

  let(:ci_builds) { table(:ci_builds) }
  let!(:ci_build) { ci_builds.create! }

  let(:security_scans) { table(:security_scans) }
  let!(:security_scan) do
    security_scans.create!(
      scan_type: 1,
      status: 1,
      build_id: ci_build.id,
      project_id: project.id,
      pipeline_id: pipeline.id
    )
  end

  let(:vulnerability_scanners) { table(:vulnerability_scanners) }
  let!(:vulnerability_scanner) { vulnerability_scanners.create!(project_id: project.id, external_id: 'test 1', name: 'test scanner 1') }

  let(:security_findings) { table(:security_findings) }
  let!(:security_finding_without_uuid) do
    security_findings.create!(
      severity: 1,
      confidence: 1,
      scan_id: security_scan.id,
      scanner_id: vulnerability_scanner.id,
      uuid: nil
    )
  end

  let!(:security_finding_with_uuid) do
    security_findings.create!(
      severity: 1,
      confidence: 1,
      scan_id: security_scan.id,
      scanner_id: vulnerability_scanner.id,
      uuid: 'bd95c085-71aa-51d7-9bb6-08ae669c262e'
    )
  end

  let(:sub_batch_size) { 10_000 }

  subject { described_class.new.perform(security_finding_without_uuid.id, security_finding_with_uuid.id, sub_batch_size) }

  it 'drops Security::Finding objects with no UUID' do
    expect { subject }.to change(security_findings, :count).from(2).to(1)
  end
end
