# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixVulnerabilitiesTransitionedFromDismissedToResolved, feature_category: :vulnerability_management do
  # rubocop:disable RSpec/MultipleMemoizedHelpers -- Favoring readability over brevity
  let(:states) do
    {
      detected: 1,
      confirmed: 4,
      resolved: 3,
      dismissed: 2
    }
  end

  let(:users) { table(:users) }
  let(:user) { create_user(email: "test1@example.com", username: "test1") }
  let(:security_policy_bot) { create_user(email: "test2@example.com", username: "test2", user_type: 10) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let(:namespaces) { table(:namespaces) }
  let(:namespace) do
    namespaces.create!(name: 'test-1', path: 'test-1', owner_id: user.id, organization_id: organization.id)
  end

  let(:outside_namespace) do
    namespaces.create!(name: 'test-2', path: 'test-2', owner_id: user.id, organization_id: organization.id)
  end

  let(:projects) { table(:projects) }
  let(:project) do
    projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, organization_id: organization.id)
  end

  let(:outside_project) do
    projects.create!(namespace_id: outside_namespace.id, project_namespace_id: outside_namespace.id,
      organization_id: organization.id)
  end

  let(:scanner) do
    table(:vulnerability_scanners, database: :sec).create!(project_id: project.id, external_id: 'semgrep',
      name: 'Semgrep')
  end

  let(:primary_identifier) do
    table(:vulnerability_identifiers, database: :sec).create!(
      project_id: project.id,
      external_id: "CVE-2018-1234",
      external_type: "CVE",
      name: "CVE-2018-1234",
      fingerprint: SecureRandom.hex(20)
    )
  end

  let(:vulnerability_findings) { table(:vulnerability_occurrences, database: :sec) }
  let(:vulnerabilities) { table(:vulnerabilities, database: :sec) }
  let(:vulnerability_reads) { table(:vulnerability_reads, database: :sec) }
  let(:state_transitions) { table(:vulnerability_state_transitions, database: :sec) }
  let(:notes) { table(:notes) }

  let!(:affected_vulnerability_inside_group) { create_affected_vulnerability(project) }
  let!(:affected_vulnerability_outside_group) { create_affected_vulnerability(outside_project) }
  let!(:affected_vulnerability_flapping) do
    vulnerability = create_affected_vulnerability(project, state: states[:detected])

    create_state_transitions(vulnerability,
      [
        {
          from_state: states[:resolved],
          to_state: states[:detected],
          comment: 'Redetected in scan'
        },
        {
          author_id: security_policy_bot.id,
          from_state: states[:detected],
          to_state: states[:resolved],
          comment: 'Auto-resolved by policy'
        },
        {
          from_state: states[:resolved],
          to_state: states[:detected],
          comment: 'Redetected in scan'
        },
        {
          author_id: security_policy_bot.id,
          from_state: states[:detected],
          to_state: states[:resolved],
          comment: 'Auto-resolved by policy'
        },
        {
          from_state: states[:resolved],
          to_state: states[:detected],
          comment: 'Redetected in scan'
        }
      ]
    )

    vulnerability
  end

  let!(:affected_vulnerability_with_human_intervention) do
    vulnerability = create_affected_vulnerability(project)

    create_state_transitions(vulnerability,
      [
        author_id: user.id,
        from_state: states[:resolved],
        to_state: states[:dismissed],
        comment: 'Go back to dismissed'
      ]
    )

    vulnerability
  end

  let!(:affected_vulnerability_before_date_of_bug) do
    vulnerability = create_vulnerability(project)

    create_state_transitions(vulnerability,
      [
        {
          author_id: user.id,
          from_state: states[:detected],
          to_state: states[:dismissed],
          comment: 'Not affected',
          created_at: Date.new(2024, 12, 4)
        },
        {
          author_id: security_policy_bot.id,
          from_state: states[:dismissed],
          to_state: states[:resolved],
          comment: 'Auto-resolved by policy',
          created_at: Date.new(2024, 12, 4)
        },
        {
          from_state: states[:resolved],
          to_state: states[:detected],
          created_at: Date.new(2024, 12, 4)
        }
      ]
    )

    vulnerability
  end

  let!(:vulnerability_with_no_state_transitions) { create_vulnerability(project) }
  let!(:confirmed_vulnerability) do
    vulnerability = create_vulnerability(project, state: states[:confirmed])

    create_state_transitions(vulnerability,
      [
        {
          author_id: user.id,
          from_state: states[:detected],
          to_state: states[:confirmed],
          comment: "It's legit."
        }
      ]
    )

    vulnerability
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: vulnerability_reads.order(vulnerability_id: :asc).pick(:vulnerability_id),
      end_id: vulnerability_reads.order(vulnerability_id: :desc).pick(:vulnerability_id),
      batch_table: :vulnerability_reads,
      batch_column: :vulnerability_id,
      sub_batch_size: vulnerability_reads.count,
      job_arguments: [namespace_id],
      pause_ms: 0,
      connection: SecApplicationRecord.connection
    ).perform
  end

  describe 'migration' do
    context 'when performing an instance migration' do
      let(:namespace_id) { 'instance' }

      it 'migrates all affected vulnerabilities' do
        expect { perform_migration }.to(
          change { affected_vulnerability_inside_group.reload.state }.from(states[:resolved]).to(states[:dismissed])
            .and(change { affected_vulnerability_outside_group.reload.state }
                 .from(states[:resolved]).to(states[:dismissed]))
            .and(change { affected_vulnerability_flapping.reload.state }.from(states[:detected]).to(states[:dismissed]))
            .and(not_change { affected_vulnerability_with_human_intervention.reload.state })
            .and(not_change { affected_vulnerability_before_date_of_bug.reload.state })
            .and(not_change { vulnerability_with_no_state_transitions.reload.state })
            .and(not_change { confirmed_vulnerability.reload.state })
        )
      end

      it 'inserts state transitions for migrated vulnerabilities', :aggregate_failures do
        perform_migration

        expect(latest_transition(affected_vulnerability_inside_group)).to have_attributes(
          comment: described_class::COMMENT,
          from_state: states[:resolved],
          to_state: states[:dismissed],
          dismissal_reason: 1,
          author_id: security_policy_bot.id,
          vulnerability_id: affected_vulnerability_inside_group.id
        )

        expect(latest_transition(affected_vulnerability_outside_group)).to have_attributes(
          comment: described_class::COMMENT,
          from_state: states[:resolved],
          to_state: states[:dismissed],
          dismissal_reason: 1,
          author_id: security_policy_bot.id,
          vulnerability_id: affected_vulnerability_outside_group.id
        )

        expect(latest_transition(affected_vulnerability_flapping)).to have_attributes(
          comment: described_class::COMMENT,
          from_state: states[:detected],
          to_state: states[:dismissed],
          dismissal_reason: 1,
          author_id: security_policy_bot.id,
          vulnerability_id: affected_vulnerability_flapping.id
        )

        expect(state_transitions.all).to all(be_valid)
      end

      it 'inserts notes for migrated vulnerabilities' do
        perform_migration

        [
          affected_vulnerability_inside_group,
          affected_vulnerability_outside_group,
          affected_vulnerability_flapping
        ].each do |vulnerability|
          expect(latest_note(vulnerability)).to have_attributes(
            project_id: vulnerability.project_id,
            namespace_id: projects.find(vulnerability.project_id).project_namespace_id,
            system: true,
            note: described_class::COMMENT,
            author_id: security_policy_bot.id
          )

          expect(notes.all).to all(be_valid)
        end
      end
    end

    context 'when migrating a namespace' do
      let(:namespace_id) { namespace.id }

      it 'only migrates records inside the namespace' do
        expect { perform_migration }.to(
          change { affected_vulnerability_inside_group.reload.state }.from(states[:resolved]).to(states[:dismissed])
            .and(change { affected_vulnerability_flapping.reload.state }.from(states[:detected]).to(states[:dismissed]))
            .and(not_change { affected_vulnerability_with_human_intervention.reload.state })
            .and(not_change { affected_vulnerability_outside_group.reload.state })
            .and(not_change { affected_vulnerability_with_human_intervention.reload.state })
            .and(not_change { affected_vulnerability_before_date_of_bug.reload.state })
            .and(not_change { vulnerability_with_no_state_transitions.reload.state })
            .and(not_change { confirmed_vulnerability.reload.state })
        )
      end

      it 'inserts state transitions for migrated vulnerabilities', :aggregate_failures do
        perform_migration

        expect(latest_transition(affected_vulnerability_inside_group)).to have_attributes(
          comment: described_class::COMMENT,
          from_state: states[:resolved],
          to_state: states[:dismissed],
          dismissal_reason: 1,
          author_id: security_policy_bot.id,
          vulnerability_id: affected_vulnerability_inside_group.id
        )

        expect(latest_transition(affected_vulnerability_outside_group)).to have_attributes(
          author_id: security_policy_bot.id,
          from_state: states[:dismissed],
          to_state: states[:resolved],
          comment: 'Auto-resolved by policy'
        )

        expect(latest_transition(affected_vulnerability_flapping)).to have_attributes(
          comment: described_class::COMMENT,
          from_state: states[:detected],
          to_state: states[:dismissed],
          dismissal_reason: 1,
          author_id: security_policy_bot.id,
          vulnerability_id: affected_vulnerability_flapping.id
        )

        expect(state_transitions.all).to all(be_valid)
      end

      it 'inserts notes for migrated vulnerabilities' do
        perform_migration

        [
          affected_vulnerability_inside_group,
          affected_vulnerability_flapping
        ].each do |vulnerability|
          expect(latest_note(vulnerability)).to have_attributes(
            project_id: vulnerability.project_id,
            namespace_id: projects.find(vulnerability.project_id).project_namespace_id,
            system: true,
            note: described_class::COMMENT,
            author_id: security_policy_bot.id
          )

          expect(notes.all).to all(be_valid)
        end
      end
    end
  end

  def latest_transition(vulnerability)
    state_transitions
      .where(vulnerability_id: vulnerability.id)
      .order(:id)
      .last
  end

  def latest_note(vulnerability)
    notes
      .where(noteable_type: 'Vulnerability', noteable_id: vulnerability.id)
      .order(:id)
      .last
  end

  def create_affected_vulnerability(project, **vulnerability_attributes)
    vulnerability = create_vulnerability(project, **vulnerability_attributes)

    create_state_transitions(vulnerability,
      [
        {
          author_id: user.id,
          from_state: states[:detected],
          to_state: states[:dismissed],
          dismissal_reason: 1,
          comment: 'Not affected'
        },
        {
          author_id: security_policy_bot.id,
          from_state: states[:dismissed],
          to_state: states[:resolved],
          comment: 'Auto-resolved by policy'
        }
      ]
    )

    vulnerability
  end

  def create_vulnerability(project, **attributes)
    finding = create_finding

    vulnerability = vulnerabilities.create!({
      project_id: project.id,
      author_id: user.id,
      title: 'test',
      severity: 1,
      report_type: 1,
      state: states[:resolved],
      finding_id: finding.id,
      present_on_default_branch: true
    }.merge(attributes))

    # execute database trigger to create vulnerability_reads record
    finding.update!(vulnerability_id: vulnerability.id)
    # Set traversal_ids which is normally handled
    # in ee/app/services/security/ingestion/tasks/ingest_vulnerability_reads/update.rb
    vulnerability_reads
      .where(vulnerability_id: vulnerability.id)
      .update_all(traversal_ids: [project.namespace_id])

    vulnerability
  end

  def create_finding
    vulnerability_findings.create!(
      project_id: project.id,
      scanner_id: scanner.id,
      severity: 5, # medium
      report_type: 99, # generic
      primary_identifier_id: primary_identifier.id,
      location_fingerprint: SecureRandom.hex(20),
      uuid: SecureRandom.uuid,
      name: "CVE-2018-1234",
      raw_metadata: "{}",
      metadata_version: "test:1.0"
    )
  end

  def create_state_transitions(vulnerability, attributes_list)
    attributes_list.each do |attributes|
      state_transitions.create!(vulnerability_id: vulnerability.id, **attributes)
    end
  end

  def create_user(**attributes)
    users.create!({
      email: "test@example.com",
      notification_email: "test@example.com",
      name: "test",
      username: "test",
      state: "active",
      projects_limit: 10
    }.merge(attributes))
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
