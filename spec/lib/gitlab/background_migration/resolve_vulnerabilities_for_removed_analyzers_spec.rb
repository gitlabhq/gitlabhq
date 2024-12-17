# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ResolveVulnerabilitiesForRemovedAnalyzers,
  schema: 20241015185528,
  feature_category: :static_application_security_testing do
  before(:all) do
    # This migration will not work if a sec database is configured. It should be finalized and removed prior to
    # sec db rollout.
    # Consult https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171707 for more info.
    skip_if_multiple_databases_are_setup(:sec)
  end

  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:scanners) { table(:vulnerability_scanners) }
  let(:scanner) { scanners.create!(project_id: project.id, external_id: 'external_id', name: 'Test Scanner') }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:vulnerability_reads) { table(:vulnerability_reads) }
  let(:vulnerability_feedback) { table(:vulnerability_feedback) }
  let(:vulnerability_state_transitions) { table(:vulnerability_state_transitions) }
  let(:vulnerability_statistics) { table(:vulnerability_statistics) }
  let(:notes) { table(:notes) }
  let(:system_note_metadata) { table(:system_note_metadata) }

  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { namespaces.create!(name: 'user', path: 'user', organization_id: organization.id) }
  let(:project) do
    projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, organization_id: organization.id)
  end

  let(:vulnerability_resolved_by_user) { Users::Internal.security_bot }
  let(:vulnerability_created_by_user) do
    table(:users).create!(username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 10)
  end

  let(:mitigating_control_dismissal_reason) { 2 }
  let(:detected_state) { described_class::Migratable::Enums::Vulnerability.vulnerability_states[:detected] }
  let(:resolved_state) { described_class::Migratable::Enums::Vulnerability.vulnerability_states[:resolved] }

  let(:sub_batch_size) { vulnerability_reads.count }
  let(:num_vulnerabilities) { vulnerabilities_to_resolve.length + vulnerabilities_not_to_resolve.length }

  let(:removed_scanners) do
    %w[
      eslint
      gosec
      bandit
      security_code_scan
      brakeman
      flawfinder
      mobsf
      njsscan
      nodejs-scan
      nodejs_scan
      phpcs_security_audit
    ]
  end

  let(:active_scanners) do
    %w[
      semgrep
      gemnasium
      trivy
      gemnasium-maven
    ]
  end

  shared_context 'with vulnerability data' do
    let!(:vulnerabilities_to_resolve) do
      removed_scanners.map do |external_id|
        create_vulnerability(project_id: project.id, external_id: external_id)
      end
    end

    let!(:vulnerabilities_not_to_resolve) do
      vulns = active_scanners.map do |external_id|
        create_vulnerability(project_id: project.id, external_id: external_id, severity: :medium)
      end

      # append a removed scanner with a dismissed state, so it won't be processed
      vulns + [create_vulnerability(project_id: project.id, external_id: removed_scanners.first,
        severity: :medium, state: :dismissed)]
    end
  end

  # use a method instead of a subject to avoid rspec memoization
  def perform_migration
    described_class.new(
      start_id: vulnerability_reads.minimum(:id),
      end_id: vulnerability_reads.maximum(:id),
      batch_table: :vulnerability_reads,
      batch_column: :id,
      sub_batch_size: sub_batch_size,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  describe "#perform", feature_category: :static_application_security_testing do
    include_context 'with vulnerability data'

    context 'for vulnerability resolution' do
      it 'resolves vulnerabilities and vulnerability_reads for removed scanners' do
        count = vulnerabilities_to_resolve.length
        expect { perform_migration }.to change {
          vulnerabilities_to_resolve.map { |v| v[:vulnerability].reload.state }
        }
        .from([detected_state] * count).to([resolved_state] * count)
        .and change {
          vulnerabilities_to_resolve.map { |v| v[:vulnerability_read].reload.state }
        }
        .from([detected_state] * count).to([resolved_state] * count)

        common_expected_attributes = {
          state: resolved_state,
          resolved_by_id: vulnerability_resolved_by_user.id,
          resolved_at: be_a_kind_of(Time)
        }

        expected_vulnerabilities = vulnerabilities_to_resolve.map do
          have_attributes(**common_expected_attributes)
        end

        expect(vulnerabilities.where(id: vulnerabilities_to_resolve.map { |v| v[:vulnerability].id }))
          .to contain_exactly(*expected_vulnerabilities)
      end

      it 'does not resolve vulnerabilities or vulnerability_reads for active scanners' do
        expect { perform_migration }.to not_change {
          vulnerabilities_not_to_resolve.map { |v| v[:vulnerability].reload.state }
        }
        .and not_change { vulnerabilities_not_to_resolve.map { |v| v[:vulnerability_read].reload.state } }
      end

      context 'when the sub_batch size is 1' do
        let(:sub_batch_size) { 1 }

        it 'does not raise an exception' do
          expect { perform_migration }.not_to raise_error
        end
      end
    end

    context 'for vulnerability state transitions' do
      it 'creates vulnerability state transitions for the resolved vulnerabilities' do
        expect { perform_migration }.to change { vulnerability_state_transitions.count }
          .from(0).to(vulnerabilities_to_resolve.count)

        common_expected_attributes = {
          comment: described_class::RESOLVED_VULNERABILITY_COMMENT,
          from_state: detected_state,
          to_state: resolved_state,
          author_id: vulnerability_resolved_by_user.id,
          project_id: project.id,
          dismissal_reason: be_nil,
          created_at: be_a_kind_of(Time),
          updated_at: be_a_kind_of(Time)
        }

        expected_state_transitions = vulnerabilities_to_resolve.map do |vulnerability|
          have_attributes(**common_expected_attributes, vulnerability_id: vulnerability[:vulnerability].id)
        end

        expect(vulnerability_state_transitions.all).to contain_exactly(*expected_state_transitions)
      end
    end

    context 'for system notes' do
      it 'creates system notes for the resolved vulnerabilities' do
        expect { perform_migration }.to change { notes.count }
          .from(0).to(vulnerabilities_to_resolve.count)

        common_expected_attributes = {
          note: described_class::RESOLVED_VULNERABILITY_COMMENT,
          noteable_type: 'Vulnerability',
          author_id: vulnerability_resolved_by_user.id,
          created_at: be_a_kind_of(Time),
          updated_at: be_a_kind_of(Time),
          project_id: project.id,
          system: be_truthy,
          namespace_id: namespace.id,
          discussion_id: /[a-f0-9]{40}/
        }

        expected_notes = vulnerabilities_to_resolve.map do |vulnerability|
          have_attributes(**common_expected_attributes, noteable_id: vulnerability[:vulnerability].id)
        end

        expect(notes.all).to contain_exactly(*expected_notes)
      end

      it 'creates system note metadata for the resolved vulnerabilities' do
        expect { perform_migration }.to change { system_note_metadata.count }
          .from(0).to(vulnerabilities_to_resolve.count)

        common_expected_attributes = {
          action: 'vulnerability_resolved',
          created_at: be_a_kind_of(Time),
          updated_at: be_a_kind_of(Time)
        }

        expected_system_note_metadata = notes.all.map do |note|
          have_attributes(**common_expected_attributes, note_id: note.id)
        end

        expect(system_note_metadata.all).to contain_exactly(*expected_system_note_metadata)
      end
    end

    context 'for vulnerability_read dismissal_reason' do
      it 'nullifies the dismissal_reason of vulnerability_reads for removed scanners' do
        count = vulnerabilities_to_resolve.length
        expect { perform_migration }.to change {
          vulnerabilities_to_resolve.map { |v| v[:vulnerability_read].reload.dismissal_reason }
        }
        .from([mitigating_control_dismissal_reason] * count).to([nil] * count)
      end

      it 'does not alter the dismissal_reason of vulnerability_reads for active scanners' do
        count = vulnerabilities_not_to_resolve.length
        expect { perform_migration }.to not_change {
          vulnerabilities_not_to_resolve.map { |v| v[:vulnerability_read].reload.dismissal_reason }
        }
        .from([mitigating_control_dismissal_reason] * count)
      end
    end

    context 'for vulnerability_statistics' do
      context 'when there are no vulnerability_statistics records' do
        it 'does not create a vulnerability_statistics record' do
          expect { perform_migration }.not_to change { vulnerability_statistics.count }.from(0)
        end
      end

      context 'when there are vulnerability_statistics records' do
        before do
          vulnerability_statistics.create!(
            project_id: project.id,
            critical: vulnerabilities_to_resolve.length,
            medium: vulnerabilities_not_to_resolve.length,
            total: num_vulnerabilities,
            letter_grade: described_class::Migratable::Vulnerabilities::Statistic.letter_grades[:f]
          )
        end

        it 'subtracts the number of resolved vulnerabilities from the total number of vulnerabilities' do
          expect { perform_migration }.to change { vulnerability_statistics.first.reload.total }
            .from(num_vulnerabilities).to(vulnerabilities_not_to_resolve.length)
        end

        it 'subtracts the num of resolved vulnerabilities from the num of vulnerabilities for the severity level' do
          expect { perform_migration }.to change { vulnerability_statistics.first.reload.critical }
            .from(vulnerabilities_to_resolve.length).to(0)
        end

        it 'adjusts the letter_grade to reflect the current vulnerabilities' do
          expect { perform_migration }.to change { vulnerability_statistics.first.reload.letter_grade }
            .from(described_class::Migratable::Vulnerabilities::Statistic.letter_grades[:f])
            .to(described_class::Migratable::Vulnerabilities::Statistic.letter_grades[:c])
        end

        context 'and the vulnerabilities to remove all belong to the same project' do
          it 'updates the vulnerability_statistics table in a single operation' do
            # warm the cache
            perform_migration

            removed_scanners.take(1).map do |external_id|
              create_vulnerability(project_id: project.id, external_id: external_id)
            end

            control = ActiveRecord::QueryRecorder.new { perform_migration }

            removed_scanners.map do |external_id|
              create_vulnerability(project_id: project.id, external_id: external_id)
            end

            expect(ActiveRecord::QueryRecorder.new { perform_migration }.count).to eq(control.count)
          end
        end

        context 'and the vulnerabilities to remove all belong to different projects' do
          it 'updates the vulnerability_statistics table in a separate operation for each project' do
            # warm the cache
            perform_migration

            removed_scanners.map do |external_id|
              create_vulnerability(project_id: project.id, external_id: external_id)
            end

            control = ActiveRecord::QueryRecorder.new { perform_migration }

            removed_scanners.map do |external_id|
              new_namespace = namespaces.create!(name: 'user', path: 'user', organization_id: organization.id)

              new_project = projects.create!(
                namespace_id: new_namespace.id,
                project_namespace_id: new_namespace.id,
                organization_id: organization.id
              )
              create_vulnerability(project_id: new_project.id, external_id: external_id)
            end

            expect(ActiveRecord::QueryRecorder.new { perform_migration }.count)
              .to eq(control.count + removed_scanners.count - 1)
          end
        end
      end
    end

    context 'for vulnerability_feedback' do
      it 'deletes dismissed vulnerability_feedback for removed scanners' do
        expect { perform_migration }.to change { vulnerability_feedback.count }
        .from(vulnerabilities_to_resolve.count + vulnerabilities_not_to_resolve.count)
        .to(vulnerabilities_not_to_resolve.count)
      end
    end
  end

  private

  def create_vulnerability(project_id:, external_id:, severity: :critical, state: :detected)
    scanner = scanners.where(project_id: project_id, external_id: external_id,
      name: "Scanner #{external_id}").first_or_create!
    severity_level = described_class::Migratable::Enums::Vulnerability.severity_levels[severity]
    vulnerability_state = described_class::Migratable::Enums::Vulnerability.vulnerability_states[state]

    uuid = SecureRandom.uuid
    project_fingerprint = SecureRandom.hex(20)

    identifier = table(:vulnerability_identifiers).create!(
      project_id: project_id,
      external_id: "CVE-2018-1234",
      external_type: "CVE",
      name: "CVE-2018-1234",
      fingerprint: SecureRandom.hex(20)
    )

    finding = table(:vulnerability_occurrences).create!(
      project_id: project_id,
      scanner_id: scanner.id,
      severity: severity_level,
      report_type: 99, # generic
      primary_identifier_id: identifier.id,
      project_fingerprint: project_fingerprint,
      location_fingerprint: SecureRandom.hex(20),
      uuid: uuid,
      name: "CVE-2018-1234",
      raw_metadata: "{}",
      metadata_version: "test:1.0"
    )

    vulnerability_feedback.create!(
      feedback_type: described_class::Migratable::Vulnerabilities::Feedback.feedback_types[:dismissal],
      project_id: project_id,
      author_id: vulnerability_created_by_user.id,
      project_fingerprint: project_fingerprint,
      category: 0, # sast
      finding_uuid: uuid
    )

    vulnerability = vulnerabilities.create!(
      project_id: project_id,
      author_id: vulnerability_created_by_user.id,
      title: 'Vulnerability 1',
      severity: severity_level,
      confidence: 1,
      report_type: 1,
      state: vulnerability_state,
      finding_id: finding.id
    )

    vulnerability_read = vulnerability_reads.create!(
      dismissal_reason: mitigating_control_dismissal_reason,
      vulnerability_id: vulnerability.id,
      namespace_id: project.namespace_id,
      project_id: project_id,
      scanner_id: scanner.id,
      report_type: 1,
      severity: severity_level,
      state: vulnerability_state,
      uuid: uuid,
      archived: false,
      traversal_ids: []
    )

    { vulnerability: vulnerability, vulnerability_read: vulnerability_read }
  end
end
