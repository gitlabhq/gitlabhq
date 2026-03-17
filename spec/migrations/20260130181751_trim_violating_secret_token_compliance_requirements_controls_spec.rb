# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe TrimViolatingSecretTokenComplianceRequirementsControls, migration: :gitlab_main, feature_category: :compliance_management do
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let(:compliance_management_frameworks) { table(:compliance_management_frameworks) }
  let(:compliance_requirements) { table(:compliance_requirements) }

  let(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }
  let(:namespace) do
    namespaces.create!(name: 'Test Group', path: 'test-group', organization_id: organization.id, type: 'Group')
  end

  let(:framework) do
    compliance_management_frameworks.create!(
      namespace_id: namespace.id,
      name: 'Test Framework',
      description: 'Test Description',
      color: '#000000'
    )
  end

  let(:requirement) do
    compliance_requirements.create!(
      framework_id: framework.id,
      namespace_id: namespace.id,
      name: 'Test Requirement',
      description: 'Test requirement description'
    )
  end

  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      ALTER TABLE compliance_requirements_controls
      DROP CONSTRAINT IF EXISTS check_compliance_requirements_controls_secret_token_max_length
    SQL
  end

  describe '#up' do
    context 'when secret_token is too long (exceeds PLAINTEXT_LIMIT)' do
      let!(:long_token_record) do
        record = described_class::ComplianceRequirementsControl.new(
          compliance_requirement_id: requirement.id,
          namespace_id: namespace.id,
          name: 0,
          control_type: 1,
          external_url: 'https://example.com'
        )
        record.secret_token = 'x' * 300
        record.save!(validate: false)
        record
      end

      it 'trims the secret_token to PLAINTEXT_LIMIT' do
        migrate!

        reloaded = described_class::ComplianceRequirementsControl.find(long_token_record.id)
        expect(reloaded.secret_token.length).to eq(240)
      end

      it 'preserves the first 240 characters of the token' do
        original_prefix = long_token_record.secret_token[0, 240]

        migrate!

        reloaded = described_class::ComplianceRequirementsControl.find(long_token_record.id)
        expect(reloaded.secret_token).to eq(original_prefix)
      end
    end

    context 'when secret_token is under PLAINTEXT_LIMIT' do
      let!(:short_token_record) do
        record = described_class::ComplianceRequirementsControl.new(
          compliance_requirement_id: requirement.id,
          namespace_id: namespace.id,
          name: 0,
          control_type: 1,
          external_url: 'https://example.com'
        )
        record.secret_token = 'x' * 100
        record.save!(validate: false)
        record
      end

      it 'does not modify the secret_token' do
        original_token = described_class::ComplianceRequirementsControl.find(short_token_record.id).secret_token

        migrate!

        reloaded = described_class::ComplianceRequirementsControl.find(short_token_record.id)
        expect(reloaded.secret_token).to eq(original_token)
      end
    end

    context 'when secret_token is exactly at PLAINTEXT_LIMIT' do
      let!(:exact_limit_record) do
        record = described_class::ComplianceRequirementsControl.new(
          compliance_requirement_id: requirement.id,
          namespace_id: namespace.id,
          name: 0,
          control_type: 1,
          external_url: 'https://example.com'
        )
        record.secret_token = 'x' * 240
        record.save!(validate: false)
        record
      end

      it 'does not modify the secret_token' do
        original_token = described_class::ComplianceRequirementsControl.find(exact_limit_record.id).secret_token

        migrate!

        reloaded = described_class::ComplianceRequirementsControl.find(exact_limit_record.id)
        expect(reloaded.secret_token).to eq(original_token)
      end
    end

    context 'when there are no violating records' do
      it 'does not raise an error' do
        expect { migrate! }.not_to raise_error
      end
    end

    context 'when migration is run multiple times' do
      let!(:violating_record) do
        record = described_class::ComplianceRequirementsControl.new(
          compliance_requirement_id: requirement.id,
          namespace_id: namespace.id,
          name: 0,
          control_type: 1,
          external_url: 'https://example.com'
        )
        record.secret_token = 'x' * 300
        record.save!(validate: false)
        record
      end

      it 'is idempotent' do
        migrate!

        first_run_token = described_class::ComplianceRequirementsControl.find(violating_record.id).secret_token

        migrate!

        second_run_token = described_class::ComplianceRequirementsControl.find(violating_record.id).secret_token

        expect(second_run_token).to eq(first_run_token)
        expect(second_run_token.length).to eq(240)
      end
    end
  end

  describe '#down' do
    it 'is a no-op' do
      expect { described_class.new.down }.not_to raise_error
    end
  end
end
