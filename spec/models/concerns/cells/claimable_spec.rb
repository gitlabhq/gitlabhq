# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cells::Claimable, feature_category: :cell do
  let(:subject_key) { :id }
  let(:test_klass) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'organizations'

      include Cells::Claimable
    end
  end

  let(:instance) { test_klass.create!(path: 'gitlab') }

  before do
    test_klass.cells_claims_attribute :path,
      type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH
    test_klass.cells_claims_metadata subject_type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION,
      subject_key: subject_key
  end

  describe 'configuration' do
    it 'retrieves cell configuration' do
      expect(test_klass.cells_claims_subject_type).to eq(Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION)
      expect(test_klass.cells_claims_source_type).to eq(Cells::Claimable::CLAIMS_SOURCE_TYPE::RAILS_TABLE_ORGANIZATIONS)
      expect(test_klass.cells_claims_attributes).to eq(
        path: { type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH }
      )
    end

    context 'when subject_key is not provided' do
      let(:subject_key) { nil }

      it 'uses default subject_key' do
        expect(test_klass.cells_claims_subject_key).to eq(:organization_id)
      end
    end

    context 'when custom subject_key is provided' do
      let(:subject_key) { :custom_id }

      it 'allows custom subject_key' do
        expect(test_klass.cells_claims_subject_key).to eq(:custom_id)
      end
    end

    it 'derives source_type from table_name when not provided' do
      expect(test_klass.cells_claims_source_type).to eq(
        Gitlab::Cells::TopologyService::Claims::V1::Source::Type::RAILS_TABLE_ORGANIZATIONS
      )
    end
  end

  describe 'callbacks' do
    let(:transaction_record) { instance_double(Cells::TransactionRecord) }

    before do
      allow(Cells::TransactionRecord).to receive(:current_transaction)
        .with(instance.connection)
        .and_return(transaction_record)
    end

    describe '#cells_claims_save_changes' do
      context 'when transaction record exists' do
        context 'when creating a new record' do
          it 'creates claims for all configured attributes' do
            instance = test_klass.new
            instance.path = 'newpath'

            expect(transaction_record).to receive(:create_record).once.with(
              {
                bucket: { type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH, value: 'newpath' },
                source: { type: Cells::Claimable::CLAIMS_SOURCE_TYPE::RAILS_TABLE_ORGANIZATIONS,
                          rails_primary_key_id: be_a(Integer) },
                subject: { type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION, id: be_a(Integer) }
              }
            )

            instance.save!
          end
        end

        context 'when updating an existing record' do
          it 'destroys old claim and creates new claim when attribute changes' do
            old_path = instance.path
            new_path = 'new-path'

            expect(transaction_record)
            .to receive(:destroy_record).with(a_hash_including(bucket: {
              type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH, value: old_path
            }))
            expect(transaction_record)
              .to receive(:create_record).with(a_hash_including(bucket: {
                type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH, value: new_path
              }))

            instance.update!(path: new_path)
          end

          it 'does not process unchanged attributes' do
            expect(transaction_record).not_to receive(:destroy_record)
            expect(transaction_record).not_to receive(:create_record)

            instance.save!
          end
        end
      end

      context 'when transaction record does not exist' do
        before do
          allow(Cells::TransactionRecord).to receive(:current_transaction).and_return(nil)
        end

        it 'does not process claims' do
          expect(transaction_record).not_to receive(:create_record)
          expect(transaction_record).not_to receive(:destroy_record)

          instance.save!
        end
      end
    end

    describe '#cells_claims_destroy_changes' do
      context 'when transaction record exists' do
        it 'destroys claims for all configured attributes' do
          old_path = instance.path

          expect(transaction_record)
            .to receive(:destroy_record).with(a_hash_including(bucket: {
              type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH, value: old_path
            }))
          instance.destroy!
        end
      end

      context 'when transaction record does not exist' do
        before do
          allow(Cells::TransactionRecord).to receive(:current_transaction).and_return(nil)
        end

        it 'does not process claims' do
          expect(transaction_record).not_to receive(:destroy_record)

          instance.destroy!
        end
      end
    end
  end

  describe '#cells_claims_default_metadata' do
    it 'returns metadata with subject and source information' do
      metadata = instance.send(:cells_claims_default_metadata)

      expect(metadata).to eq({
        subject: { type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION, id: instance.id },
        source: { type: Cells::Claimable::CLAIMS_SOURCE_TYPE::RAILS_TABLE_ORGANIZATIONS,
                  rails_primary_key_id: instance.id }
      })
    end
  end
end
