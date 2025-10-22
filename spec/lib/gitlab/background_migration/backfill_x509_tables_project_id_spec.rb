# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillX509TablesProjectId, feature_category: :source_code_management do
  let(:x509_issuers) { table(:x509_issuers) }
  let(:x509_certificates) { table(:x509_certificates) }
  let(:x509_commit_signatures) { table(:x509_commit_signatures) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }

  let(:organization) do
    organizations.find_or_create_by!(path: 'default') do |org|
      org.name = 'default'
    end
  end

  let!(:namespace) { namespaces.create!(name: 'test', path: 'test', organization_id: organization.id) }

  let(:project_namespace_1) do
    namespaces.create!(
      name: 'namespace1',
      path: 'namespace-path-1',
      type: 'Project',
      organization_id: organization.id
    )
  end

  let(:project_namespace_2) do
    namespaces.create!(
      name: 'namespace2',
      path: 'namespace-path-2',
      type: 'Project',
      organization_id: organization.id
    )
  end

  let!(:project1) do
    projects.create!(
      name: 'project1',
      path: 'path1',
      namespace_id: namespace.id,
      project_namespace_id: project_namespace_1.id,
      organization_id: organization.id
    )
  end

  let!(:project2) do
    projects.create!(
      name: 'project2',
      path: 'path2',
      namespace_id: namespace.id,
      project_namespace_id: project_namespace_2.id,
      organization_id: organization.id
    )
  end

  let!(:issuer1) { x509_issuers.create!(subject_key_identifier: 'issuer1', subject: 'CN=Issuer1') }
  let!(:issuer2) { x509_issuers.create!(subject_key_identifier: 'issuer2', subject: 'CN=Issuer2') }

  let!(:certificate1) do
    x509_certificates.create!(
      x509_issuer_id: issuer1.id,
      subject_key_identifier: 'cert1',
      subject: 'CN=Cert1',
      email: 'cert1@example.com',
      serial_number: 1
    )
  end

  let!(:certificate2) do
    x509_certificates.create!(
      x509_issuer_id: issuer2.id,
      subject_key_identifier: 'cert2',
      subject: 'CN=Cert2',
      email: 'cert2@example.com',
      serial_number: 2
    )
  end

  let!(:certificate3) do
    x509_certificates.create!(
      x509_issuer_id: issuer1.id,
      subject_key_identifier: 'cert3',
      subject: 'CN=Cert3',
      email: 'cert3@example.com',
      serial_number: 3
    )
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: x509_commit_signatures.minimum(:id),
      end_id: x509_commit_signatures.maximum(:id),
      batch_table: :x509_commit_signatures,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  describe '#perform' do
    context 'when there are no x509_commit_signatures' do
      it 'does not update any records' do
        expect { perform_migration }
          .to not_change { x509_certificates.pluck(:id, :project_id) }
          .and not_change { x509_issuers.pluck(:id, :project_id) }
      end
    end

    context 'when there are x509_commit_signatures' do
      let!(:signature1) do
        x509_commit_signatures.create!(
          x509_certificate_id: certificate1.id,
          project_id: project1.id,
          commit_sha: 'abc123'
        )
      end

      let!(:signature2) do
        x509_commit_signatures.create!(
          x509_certificate_id: certificate2.id,
          project_id: project2.id,
          commit_sha: 'def456'
        )
      end

      it 'updates both x509_certificates and x509_issuers but not the certificate without signature' do
        expect { perform_migration }
          .to change { certificate1.reload.project_id }.from(nil).to(project1.id)
          .and change { certificate2.reload.project_id }.from(nil).to(project2.id)
          .and change { issuer1.reload.project_id }.from(nil).to(project1.id)
          .and change { issuer2.reload.project_id }.from(nil).to(project2.id)

        expect(certificate3.reload.project_id).to be_nil
      end

      context 'when certificates already have project_id' do
        before do
          certificate1.update!(project_id: project2.id)
          issuer1.update!(project_id: project2.id)
        end

        it 'does not overwrite existing project_id' do
          expect { perform_migration }
            .to not_change { certificate1.reload.project_id }
            .and not_change { issuer1.reload.project_id }
        end
      end
    end

    context 'when a certificate belongs to multiple projects' do
      let!(:signature1) do
        x509_commit_signatures.create!(
          x509_certificate_id: certificate1.id,
          project_id: project1.id,
          commit_sha: 'abc123'
        )
      end

      let!(:signature2) do
        x509_commit_signatures.create!(
          x509_certificate_id: certificate1.id,
          project_id: project2.id,
          commit_sha: 'def456'
        )
      end

      it 'updates certificate with project_id from one of the signatures' do
        perform_migration

        certificate1.reload
        expect(certificate1.project_id).to be_in([project1.id, project2.id])

        issuer1.reload
        expect(issuer1.project_id).to eq(certificate1.project_id)
      end
    end

    context 'when multiple certificates share the same issuer' do
      let!(:signature1) do
        x509_commit_signatures.create!(
          x509_certificate_id: certificate1.id,
          project_id: project1.id,
          commit_sha: 'abc123'
        )
      end

      let!(:signature2) do
        x509_commit_signatures.create!(
          x509_certificate_id: certificate3.id,
          project_id: project2.id,
          commit_sha: 'ghi789'
        )
      end

      it 'updates issuer with project_id from one of the certificates' do
        perform_migration

        certificate1.reload
        certificate3.reload
        issuer1.reload

        expect(certificate1.project_id).to eq(project1.id)
        expect(certificate3.project_id).to eq(project2.id)
        expect(issuer1.project_id).to be_in([project1.id, project2.id])
      end
    end

    context 'with empty batches' do
      it 'handles empty batches gracefully' do
        empty_migration = described_class.new(
          start_id: 1_000_000,
          end_id: 1_000_100,
          batch_table: :x509_commit_signatures,
          batch_column: :id,
          sub_batch_size: 10,
          pause_ms: 0,
          connection: ApplicationRecord.connection
        )

        expect { empty_migration.perform }.not_to raise_error
      end
    end

    context 'when processing in batches' do
      let!(:signature1) do
        x509_commit_signatures.create!(
          x509_certificate_id: certificate1.id,
          project_id: project1.id,
          commit_sha: 'abc123'
        )
      end

      let!(:signature2) do
        x509_commit_signatures.create!(
          x509_certificate_id: certificate2.id,
          project_id: project2.id,
          commit_sha: 'def456'
        )
      end

      let!(:signature3) do
        x509_commit_signatures.create!(
          x509_certificate_id: certificate3.id,
          project_id: project1.id,
          commit_sha: 'ghi789'
        )
      end

      it 'processes all records across batches' do
        # Using sub_batch_size: 2, so this should process in multiple batches
        expect { perform_migration }
          .to change { certificate1.reload.project_id }.from(nil).to(project1.id)
          .and change { certificate2.reload.project_id }.from(nil).to(project2.id)
          .and change { certificate3.reload.project_id }.from(nil).to(project1.id)
          .and change { issuer1.reload.project_id }.from(nil).to(project1.id)
          .and change { issuer2.reload.project_id }.from(nil).to(project2.id)
      end
    end
  end
end
