# frozen_string_literal: true

require 'spec_helper'

def create_background_migration_job(ids, status)
  proper_status = case status
                  when :pending
                    Gitlab::Database::BackgroundMigrationJob.statuses['pending']
                  when :succeeded
                    Gitlab::Database::BackgroundMigrationJob.statuses['succeeded']
                  else
                    raise ArgumentError
                  end

  background_migration_jobs.create!(
    class_name: 'RecalculateVulnerabilitiesOccurrencesUuid',
    arguments: Array(ids),
    status: proper_status,
    created_at: Time.now.utc
  )
end

RSpec.describe Gitlab::BackgroundMigration::RecalculateVulnerabilitiesOccurrencesUuid, :suppress_gitlab_schemas_validate_connection, schema: 20211202041233 do
  let(:background_migration_jobs) { table(:background_migration_jobs) }
  let(:pending_jobs) { background_migration_jobs.where(status: Gitlab::Database::BackgroundMigrationJob.statuses['pending']) }
  let(:succeeded_jobs) { background_migration_jobs.where(status: Gitlab::Database::BackgroundMigrationJob.statuses['succeeded']) }
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:users) { table(:users) }
  let(:user) { create_user! }
  let(:project) { table(:projects).create!(id: 123, namespace_id: namespace.id) }
  let(:scanners) { table(:vulnerability_scanners) }
  let(:scanner) { scanners.create!(project_id: project.id, external_id: 'test 1', name: 'test scanner 1') }
  let(:scanner2) { scanners.create!(project_id: project.id, external_id: 'test 2', name: 'test scanner 2') }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:vulnerability_findings) { table(:vulnerability_occurrences) }
  let(:vulnerability_finding_pipelines) { table(:vulnerability_occurrence_pipelines) }
  let(:vulnerability_finding_signatures) { table(:vulnerability_finding_signatures) }
  let(:vulnerability_identifiers) { table(:vulnerability_identifiers) }

  let(:identifier_1) { 'identifier-1' }
  let!(:vulnerability_identifier) do
    vulnerability_identifiers.create!(
      project_id: project.id,
      external_type: identifier_1,
      external_id: identifier_1,
      fingerprint: Gitlab::Database::ShaAttribute.serialize('ff9ef548a6e30a0462795d916f3f00d1e2b082ca'),
      name: 'Identifier 1')
  end

  let(:identifier_2) { 'identifier-2' }
  let!(:vulnerability_identfier2) do
    vulnerability_identifiers.create!(
      project_id: project.id,
      external_type: identifier_2,
      external_id: identifier_2,
      fingerprint: Gitlab::Database::ShaAttribute.serialize('4299e8ddd819f9bde9cfacf45716724c17b5ddf7'),
      name: 'Identifier 2')
  end

  let(:identifier_3) { 'identifier-3' }
  let!(:vulnerability_identifier3) do
    vulnerability_identifiers.create!(
      project_id: project.id,
      external_type: identifier_3,
      external_id: identifier_3,
      fingerprint: Gitlab::Database::ShaAttribute.serialize('8e91632f9c6671e951834a723ee221c44cc0d844'),
      name: 'Identifier 3')
  end

  let(:known_uuid_v4) { "b3cc2518-5446-4dea-871c-89d5e999c1ac" }
  let(:known_uuid_v5) { "05377088-dc26-5161-920e-52a7159fdaa1" }
  let(:desired_uuid_v5) { "f3e9a23f-9181-54bf-a5ab-c5bc7a9b881a" }

  subject { described_class.new.perform(start_id, end_id) }

  context "when finding has a UUIDv4" do
    before do
      @uuid_v4 = create_finding!(
        vulnerability_id: nil,
        project_id: project.id,
        scanner_id: scanner2.id,
        primary_identifier_id: vulnerability_identfier2.id,
        report_type: 0, # "sast"
        location_fingerprint: Gitlab::Database::ShaAttribute.serialize("fa18f432f1d56675f4098d318739c3cd5b14eb3e"),
        uuid: known_uuid_v4
      )
    end

    let(:start_id) { @uuid_v4.id }
    let(:end_id) { @uuid_v4.id }

    it "replaces it with UUIDv5" do
      expect(vulnerability_findings.pluck(:uuid)).to match_array([known_uuid_v4])

      subject

      expect(vulnerability_findings.pluck(:uuid)).to match_array([desired_uuid_v5])
    end

    it 'logs recalculation' do
      expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |instance|
        expect(instance).to receive(:info).twice
      end

      subject
    end
  end

  context "when finding has a UUIDv5" do
    before do
      @uuid_v5 = create_finding!(
        vulnerability_id: nil,
        project_id: project.id,
        scanner_id: scanner.id,
        primary_identifier_id: vulnerability_identifier.id,
        report_type: 0, # "sast"
        location_fingerprint: Gitlab::Database::ShaAttribute.serialize("838574be0210968bf6b9f569df9c2576242cbf0a"),
        uuid: known_uuid_v5
      )
    end

    let(:start_id) { @uuid_v5.id }
    let(:end_id) { @uuid_v5.id }

    it "stays the same" do
      expect(vulnerability_findings.pluck(:uuid)).to match_array([known_uuid_v5])

      subject

      expect(vulnerability_findings.pluck(:uuid)).to match_array([known_uuid_v5])
    end
  end

  context 'if a duplicate UUID would be generated' do # rubocop: disable RSpec/MultipleMemoizedHelpers
    let(:v1) do
      create_vulnerability!(
        project_id: project.id,
        author_id: user.id
      )
    end

    let!(:finding_with_incorrect_uuid) do
      create_finding!(
        vulnerability_id: v1.id,
        project_id: project.id,
        scanner_id: scanner.id,
        primary_identifier_id: vulnerability_identifier.id,
        report_type: 0, # "sast"
        location_fingerprint: Gitlab::Database::ShaAttribute.serialize('ca41a2544e941a007a73a666cb0592b255316ab8'), # sha1('youshouldntusethis')
        uuid: 'bd95c085-71aa-51d7-9bb6-08ae669c262e'
      )
    end

    let(:v2) do
      create_vulnerability!(
        project_id: project.id,
        author_id: user.id
      )
    end

    let!(:finding_with_correct_uuid) do
      create_finding!(
        vulnerability_id: v2.id,
        project_id: project.id,
        primary_identifier_id: vulnerability_identifier.id,
        scanner_id: scanner2.id,
        report_type: 0, # "sast"
        location_fingerprint: Gitlab::Database::ShaAttribute.serialize('ca41a2544e941a007a73a666cb0592b255316ab8'), # sha1('youshouldntusethis')
        uuid: '91984483-5efe-5215-b471-d524ac5792b1'
      )
    end

    let(:v3) do
      create_vulnerability!(
        project_id: project.id,
        author_id: user.id
      )
    end

    let!(:finding_with_incorrect_uuid2) do
      create_finding!(
        vulnerability_id: v3.id,
        project_id: project.id,
        scanner_id: scanner.id,
        primary_identifier_id: vulnerability_identfier2.id,
        report_type: 0, # "sast"
        location_fingerprint: Gitlab::Database::ShaAttribute.serialize('ca41a2544e941a007a73a666cb0592b255316ab8'), # sha1('youshouldntusethis')
        uuid: '00000000-1111-2222-3333-444444444444'
      )
    end

    let(:v4) do
      create_vulnerability!(
        project_id: project.id,
        author_id: user.id
      )
    end

    let!(:finding_with_correct_uuid2) do
      create_finding!(
        vulnerability_id: v4.id,
        project_id: project.id,
        scanner_id: scanner2.id,
        primary_identifier_id: vulnerability_identfier2.id,
        report_type: 0, # "sast"
        location_fingerprint: Gitlab::Database::ShaAttribute.serialize('ca41a2544e941a007a73a666cb0592b255316ab8'), # sha1('youshouldntusethis')
        uuid: '1edd751e-ef9a-5391-94db-a832c8635bfc'
      )
    end

    let!(:finding_with_incorrect_uuid3) do
      create_finding!(
        vulnerability_id: nil,
        project_id: project.id,
        scanner_id: scanner.id,
        primary_identifier_id: vulnerability_identifier3.id,
        report_type: 0, # "sast"
        location_fingerprint: Gitlab::Database::ShaAttribute.serialize('ca41a2544e941a007a73a666cb0592b255316ab8'), # sha1('youshouldntusethis')
        uuid: '22222222-3333-4444-5555-666666666666'
      )
    end

    let!(:duplicate_not_in_the_same_batch) do
      create_finding!(
        id: 99999,
        vulnerability_id: nil,
        project_id: project.id,
        scanner_id: scanner2.id,
        primary_identifier_id: vulnerability_identifier3.id,
        report_type: 0, # "sast"
        location_fingerprint: Gitlab::Database::ShaAttribute.serialize('ca41a2544e941a007a73a666cb0592b255316ab8'), # sha1('youshouldntusethis')
        uuid: '4564f9d5-3c6b-5cc3-af8c-7c25285362a7'
      )
    end

    let(:start_id) { finding_with_incorrect_uuid.id }
    let(:end_id) { finding_with_incorrect_uuid3.id }

    before do
      4.times do
        create_finding_pipeline!(project_id: project.id, finding_id: finding_with_incorrect_uuid.id)
        create_finding_pipeline!(project_id: project.id, finding_id: finding_with_correct_uuid.id)
        create_finding_pipeline!(project_id: project.id, finding_id: finding_with_incorrect_uuid2.id)
        create_finding_pipeline!(project_id: project.id, finding_id: finding_with_correct_uuid2.id)
      end
    end

    it 'drops duplicates and related records', :aggregate_failures do
      expect(vulnerability_findings.pluck(:id)).to match_array(
        [
          finding_with_correct_uuid.id,
          finding_with_incorrect_uuid.id,
          finding_with_correct_uuid2.id,
          finding_with_incorrect_uuid2.id,
          finding_with_incorrect_uuid3.id,
          duplicate_not_in_the_same_batch.id
        ])

      expect { subject }.to change(vulnerability_finding_pipelines, :count).from(16).to(8)
        .and change(vulnerability_findings, :count).from(6).to(3)
        .and change(vulnerabilities, :count).from(4).to(2)

      expect(vulnerability_findings.pluck(:id)).to match_array([finding_with_incorrect_uuid.id, finding_with_incorrect_uuid2.id, finding_with_incorrect_uuid3.id])
    end

    context 'if there are conflicting UUID values within the batch' do # rubocop: disable RSpec/MultipleMemoizedHelpers
      let(:end_id) { finding_with_broken_data_integrity.id }
      let(:vulnerability_5) { create_vulnerability!(project_id: project.id, author_id: user.id) }
      let(:different_project) { table(:projects).create!(namespace_id: namespace.id) }
      let!(:identifier_with_broken_data_integrity) do
        vulnerability_identifiers.create!(
          project_id: different_project.id,
          external_type: identifier_2,
          external_id: identifier_2,
          fingerprint: Gitlab::Database::ShaAttribute.serialize('4299e8ddd819f9bde9cfacf45716724c17b5ddf7'),
          name: 'Identifier 2')
      end

      let(:finding_with_broken_data_integrity) do
        create_finding!(
          vulnerability_id: vulnerability_5,
          project_id: project.id,
          scanner_id: scanner.id,
          primary_identifier_id: identifier_with_broken_data_integrity.id,
          report_type: 0, # "sast"
          location_fingerprint: Gitlab::Database::ShaAttribute.serialize('ca41a2544e941a007a73a666cb0592b255316ab8'), # sha1('youshouldntusethis')
          uuid: SecureRandom.uuid
        )
      end

      it 'deletes the conflicting record' do
        expect { subject }.to change { vulnerability_findings.find_by_id(finding_with_broken_data_integrity.id) }.to(nil)
      end
    end

    context 'if a conflicting UUID is found during the migration' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:finding_class) { Gitlab::BackgroundMigration::RecalculateVulnerabilitiesOccurrencesUuid::VulnerabilitiesFinding }
      let(:uuid) { '4564f9d5-3c6b-5cc3-af8c-7c25285362a7' }

      before do
        exception = ActiveRecord::RecordNotUnique.new("(uuid)=(#{uuid})")

        call_count = 0
        allow(::Gitlab::Database::BulkUpdate).to receive(:execute) do
          call_count += 1
          call_count.eql?(1) ? raise(exception) : {}
        end

        allow(finding_class).to receive(:find_by).with(uuid: uuid).and_return(duplicate_not_in_the_same_batch)
      end

      it 'retries the recalculation' do
        subject

        expect(Gitlab::BackgroundMigration::RecalculateVulnerabilitiesOccurrencesUuid::VulnerabilitiesFinding)
          .to have_received(:find_by).with(uuid: uuid).once
      end

      it 'logs the conflict' do
        expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |instance|
          expect(instance).to receive(:info).exactly(6).times
        end

        subject
      end

      it 'marks the job as done' do
        create_background_migration_job([start_id, end_id], :pending)

        subject

        expect(pending_jobs.count).to eq(0)
        expect(succeeded_jobs.count).to eq(1)
      end
    end

    it 'logs an exception if a different uniquness problem was found' do
      exception = ActiveRecord::RecordNotUnique.new("Totally not an UUID uniqueness problem")
      allow(::Gitlab::Database::BulkUpdate).to receive(:execute).and_raise(exception)
      allow(Gitlab::ErrorTracking).to receive(:track_and_raise_exception)

      subject

      expect(Gitlab::ErrorTracking).to have_received(:track_and_raise_exception).with(exception).once
    end

    it 'logs a duplicate found message' do
      expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |instance|
        expect(instance).to receive(:info).exactly(3).times
      end

      subject
    end
  end

  context 'when finding has a signature' do
    before do
      @f1 = create_finding!(
        vulnerability_id: nil,
        project_id: project.id,
        scanner_id: scanner.id,
        primary_identifier_id: vulnerability_identifier.id,
        report_type: 0, # "sast"
        location_fingerprint: Gitlab::Database::ShaAttribute.serialize('ca41a2544e941a007a73a666cb0592b255316ab8'), # sha1('youshouldntusethis')
        uuid: 'd15d774d-e4b1-5a1b-929b-19f2a53e35ec'
      )

      vulnerability_finding_signatures.create!(
        finding_id: @f1.id,
        algorithm_type: 2, # location
        signature_sha: Gitlab::Database::ShaAttribute.serialize('57d4e05205f6462a73f039a5b2751aa1ab344e6e') # sha1('youshouldusethis')
      )

      vulnerability_finding_signatures.create!(
        finding_id: @f1.id,
        algorithm_type: 1, # hash
        signature_sha: Gitlab::Database::ShaAttribute.serialize('c554d8d8df1a7a14319eafdaae24af421bf5b587') # sha1('andnotthis')
      )

      @f2 = create_finding!(
        vulnerability_id: nil,
        project_id: project.id,
        scanner_id: scanner.id,
        primary_identifier_id: vulnerability_identfier2.id,
        report_type: 0, # "sast"
        location_fingerprint: Gitlab::Database::ShaAttribute.serialize('ca41a2544e941a007a73a666cb0592b255316ab8'), # sha1('youshouldntusethis')
        uuid: '4be029b5-75e5-5ac0-81a2-50ab41726135'
      )

      vulnerability_finding_signatures.create!(
        finding_id: @f2.id,
        algorithm_type: 2, # location
        signature_sha: Gitlab::Database::ShaAttribute.serialize('57d4e05205f6462a73f039a5b2751aa1ab344e6e') # sha1('youshouldusethis')
      )

      vulnerability_finding_signatures.create!(
        finding_id: @f2.id,
        algorithm_type: 1, # hash
        signature_sha: Gitlab::Database::ShaAttribute.serialize('c554d8d8df1a7a14319eafdaae24af421bf5b587') # sha1('andnotthis')
      )
    end

    let(:start_id) { @f1.id }
    let(:end_id) { @f2.id }

    let(:uuids_before) { [@f1.uuid, @f2.uuid] }
    let(:uuids_after) { %w[d3b60ddd-d312-5606-b4d3-ad058eebeacb 349d9bec-c677-5530-a8ac-5e58889c3b1a] }

    it 'is recalculated using signature' do
      expect(vulnerability_findings.pluck(:uuid)).to match_array(uuids_before)

      subject

      expect(vulnerability_findings.pluck(:uuid)).to match_array(uuids_after)
    end
  end

  context 'if all records are removed before the job ran' do
    let(:start_id) { 1 }
    let(:end_id) { 9 }

    before do
      create_background_migration_job([start_id, end_id], :pending)
    end

    it 'does not error out' do
      expect { subject }.not_to raise_error
    end

    it 'marks the job as done' do
      subject

      expect(pending_jobs.count).to eq(0)
      expect(succeeded_jobs.count).to eq(1)
    end
  end

  context 'when recalculation fails' do
    before do
      @uuid_v4 = create_finding!(
        vulnerability_id: nil,
        project_id: project.id,
        scanner_id: scanner2.id,
        primary_identifier_id: vulnerability_identfier2.id,
        report_type: 0, # "sast"
        location_fingerprint: Gitlab::Database::ShaAttribute.serialize("fa18f432f1d56675f4098d318739c3cd5b14eb3e"),
        uuid: known_uuid_v4
      )

      allow(Gitlab::ErrorTracking).to receive(:track_and_raise_exception)
      allow(::Gitlab::Database::BulkUpdate).to receive(:execute).and_raise(expected_error)
    end

    let(:start_id) { @uuid_v4.id }
    let(:end_id) { @uuid_v4.id }
    let(:expected_error) { RuntimeError.new }

    it 'captures the errors and does not crash entirely' do
      expect { subject }.not_to raise_error

      allow(Gitlab::ErrorTracking).to receive(:track_and_raise_exception)
      expect(Gitlab::ErrorTracking).to have_received(:track_and_raise_exception).with(expected_error).once
    end

    it_behaves_like 'marks background migration job records' do
      let(:arguments) { [1, 4] }
      subject { described_class.new }
    end
  end

  it_behaves_like 'marks background migration job records' do
    let(:arguments) { [1, 4] }
    subject { described_class.new }
  end

  private

  def create_vulnerability!(project_id:, author_id:, title: 'test', severity: 7, confidence: 7, report_type: 0)
    vulnerabilities.create!(
      project_id: project_id,
      author_id: author_id,
      title: title,
      severity: severity,
      confidence: confidence,
      report_type: report_type
    )
  end

  # rubocop:disable Metrics/ParameterLists
  def create_finding!(
    vulnerability_id:, project_id:, scanner_id:, primary_identifier_id:, id: nil,
                      name: "test", severity: 7, confidence: 7, report_type: 0,
                      project_fingerprint: '123qweasdzxc', location_fingerprint: 'test',
                      metadata_version: 'test', raw_metadata: 'test', uuid: SecureRandom.uuid)
    vulnerability_findings.create!({
        id: id,
        vulnerability_id: vulnerability_id,
        project_id: project_id,
        name: name,
        severity: severity,
        confidence: confidence,
        report_type: report_type,
        project_fingerprint: project_fingerprint,
        scanner_id: scanner_id,
        primary_identifier_id: primary_identifier_id,
        location_fingerprint: location_fingerprint,
        metadata_version: metadata_version,
        raw_metadata: raw_metadata,
        uuid: uuid
      }.compact
                                  )
  end
  # rubocop:enable Metrics/ParameterLists

  def create_user!(name: "Example User", email: "user@example.com", user_type: nil, created_at: Time.zone.now, confirmed_at: Time.zone.now)
    users.create!(
      name: name,
      email: email,
      username: name,
      projects_limit: 0,
      user_type: user_type,
      confirmed_at: confirmed_at
    )
  end

  def create_finding_pipeline!(project_id:, finding_id:)
    pipeline = table(:ci_pipelines).create!(project_id: project_id)
    vulnerability_finding_pipelines.create!(pipeline_id: pipeline.id, occurrence_id: finding_id)
  end
end
