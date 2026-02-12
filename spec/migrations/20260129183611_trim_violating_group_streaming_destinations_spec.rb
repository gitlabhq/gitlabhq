# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe TrimViolatingGroupStreamingDestinations, migration: :gitlab_main_org, feature_category: :audit_events do
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }
  let(:namespace) do
    namespaces.create!(name: 'Test Group', path: 'test-group', organization_id: organization.id, type: 'Group')
  end

  let(:gcp_config) do
    {
      'googleProjectIdName' => 'valid-project-id',
      'clientEmail' => 'test@example.com',
      'logIdName' => 'audit-events'
    }
  end

  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      ALTER TABLE audit_events_group_external_streaming_destinations
      DROP CONSTRAINT IF EXISTS check_audit_event_streams_group_secret_token_max_length
    SQL
  end

  describe '#up' do
    context 'when secret_token is too long (exceeds PLAINTEXT_LIMIT)' do
      let!(:long_token_record) do
        record = described_class::GroupExternalStreamingDestination.new(
          group_id: namespace.id,
          category: 1,
          name: 'Test Destination',
          config: gcp_config,
          active: true
        )
        record.secret_token = 'x' * 5000
        record.save!(validate: false)
        record
      end

      it 'trims the secret_token to PLAINTEXT_LIMIT' do
        migrate!

        reloaded = described_class::GroupExternalStreamingDestination.find(long_token_record.id)
        expect(reloaded.secret_token.length).to eq(4096)
      end

      it 'prefixes the name with [INVALID] and truncates to MAX_NAME_LENGTH' do
        original_name = long_token_record.name

        migrate!

        reloaded = described_class::GroupExternalStreamingDestination.find(long_token_record.id)
        expected_name = "[INVALID] #{original_name}"[0, 72]
        expect(reloaded.name).to eq(expected_name)
      end

      it 'sets active to false' do
        migrate!

        reloaded = described_class::GroupExternalStreamingDestination.find(long_token_record.id)
        expect(reloaded.active).to be false
      end

      context 'when the name with prefix would exceed MAX_NAME_LENGTH' do
        let!(:long_name_record) do
          record = described_class::GroupExternalStreamingDestination.new(
            group_id: namespace.id,
            category: 1,
            name: 'A' * 70,
            config: gcp_config,
            active: true
          )
          record.secret_token = 'x' * 5000
          record.save!(validate: false)
          record
        end

        it 'truncates the prefixed name to MAX_NAME_LENGTH' do
          migrate!

          reloaded = described_class::GroupExternalStreamingDestination.find(long_name_record.id)
          expect(reloaded.name.length).to eq(72)
          expect(reloaded.name).to start_with('[INVALID]')
        end
      end
    end

    context 'when multiple records violate in the same batch' do
      let!(:violating_records) do
        Array.new(3) do |i|
          record = described_class::GroupExternalStreamingDestination.new(
            group_id: namespace.id,
            category: 1,
            name: "Destination #{i}",
            config: gcp_config,
            active: true
          )
          record.secret_token = 'x' * 5000
          record.save!(validate: false)
          record
        end
      end

      it 'updates all violating records in a single batch' do
        migrate!

        violating_records.each do |original|
          reloaded = described_class::GroupExternalStreamingDestination.find(original.id)
          expect(reloaded.secret_token.length).to eq(4096)
          expect(reloaded.name).to start_with('[INVALID]')
          expect(reloaded.active).to be false
        end
      end
    end

    context 'when secret_token is under PLAINTEXT_LIMIT' do
      let!(:short_token_record) do
        record = described_class::GroupExternalStreamingDestination.new(
          group_id: namespace.id,
          category: 1,
          name: 'Valid Destination',
          config: gcp_config,
          active: true
        )
        record.secret_token = 'x' * 2000
        record.save!(validate: false)
        record
      end

      it 'does not modify the secret_token' do
        original_token = described_class::GroupExternalStreamingDestination.find(short_token_record.id).secret_token

        migrate!

        reloaded = described_class::GroupExternalStreamingDestination.find(short_token_record.id)
        expect(reloaded.secret_token).to eq(original_token)
      end

      it 'does not modify the name' do
        original_name = short_token_record.name

        migrate!

        reloaded = described_class::GroupExternalStreamingDestination.find(short_token_record.id)
        expect(reloaded.name).to eq(original_name)
      end

      it 'does not modify the active status' do
        migrate!

        reloaded = described_class::GroupExternalStreamingDestination.find(short_token_record.id)
        expect(reloaded.active).to be true
      end
    end

    context 'when there are no violating records' do
      it 'does not raise an error' do
        expect { migrate! }.not_to raise_error
      end
    end

    context 'when migration is run multiple times' do
      let!(:violating_record) do
        record = described_class::GroupExternalStreamingDestination.new(
          group_id: namespace.id,
          category: 1,
          name: 'Test',
          config: gcp_config,
          active: true
        )
        record.secret_token = 'x' * 5000
        record.save!(validate: false)
        record
      end

      it 'is idempotent' do
        migrate!

        first_run_state = {
          name: described_class::GroupExternalStreamingDestination.find(violating_record.id).name,
          active: described_class::GroupExternalStreamingDestination.find(violating_record.id).active,
          token_length: described_class::GroupExternalStreamingDestination.find(violating_record.id).secret_token.length
        }

        migrate!

        second_run_state = {
          name: described_class::GroupExternalStreamingDestination.find(violating_record.id).name,
          active: described_class::GroupExternalStreamingDestination.find(violating_record.id).active,
          token_length: described_class::GroupExternalStreamingDestination.find(violating_record.id).secret_token.length
        }

        expect(second_run_state).to eq(first_run_state)
      end
    end
  end

  describe '#down' do
    it 'is a no-op' do
      expect { described_class.new.down }.not_to raise_error
    end
  end
end
