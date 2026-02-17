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
    test_klass.cells_claims_attribute :path, type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH,
      feature_flag: :cells_claims_organizations
    test_klass.cells_claims_metadata subject_type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION,
      subject_key: subject_key
  end

  describe 'configuration' do
    it 'retrieves cell configuration' do
      expect(test_klass.cells_claims_subject_type).to eq(Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION)
      expect(test_klass.cells_claims_source_type).to eq(Cells::Claimable::CLAIMS_SOURCE_TYPE::RAILS_TABLE_ORGANIZATIONS)
      expect(test_klass.cells_claims_attributes).to eq(
        path: { type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH,
                feature_flag: :cells_claims_organizations }
      )
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
      allow(Cells::TransactionRecord)
        .to receive(:current_transaction).with(instance.connection).and_return(transaction_record)
    end

    describe '#cells_claims_save_changes' do
      context 'when transaction record exists' do
        shared_examples 'creating a new record' do
          it 'creates claims for all configured attributes' do
            instance = test_klass.new
            instance.path = 'newpath'

            expect(transaction_record).to receive(:create_record).once.with(
              {
                bucket: { type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH, value: 'newpath' },
                source: { type: Cells::Claimable::CLAIMS_SOURCE_TYPE::RAILS_TABLE_ORGANIZATIONS,
                          rails_primary_key_id: be_a(String) },
                subject: { type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION, id: be_a(Integer) },
                record: instance
              }
            )

            instance.save!
          end
        end

        it_behaves_like 'creating a new record'

        context 'when subject_key is set with a Proc' do
          let(:subject_key) { -> { path.size } }

          it_behaves_like 'creating a new record'
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

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(cells_claims_organizations: false)
        end

        it 'does not create or destroy claims' do
          expect(transaction_record).not_to receive(:create_record)
          expect(transaction_record).not_to receive(:destroy_record)

          instance.update!(path: 'new-path')
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

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(cells_claims_organizations: false)
        end

        it 'does not destroy claims' do
          expect(transaction_record).not_to receive(:destroy_record)

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
    context 'when instance ID is integer' do
      it 'returns metadata with subject and source information' do
        metadata = instance.send(:cells_claims_default_metadata)

        expect(metadata).to include({
          subject: { type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION, id: instance.id },
          source: {
            type: Cells::Claimable::CLAIMS_SOURCE_TYPE::RAILS_TABLE_ORGANIZATIONS,
            rails_primary_key_id: be_a(String)
          },
          record: instance
        })

        rails_pk_bytes = metadata[:source][:rails_primary_key_id]
        expect(rails_pk_bytes.encoding).to eq(Encoding::ASCII_8BIT)
        expect(rails_pk_bytes.bytesize).to eq(8)
        expect(rails_pk_bytes.unpack1("Q>")).to eq(instance.id)
      end
    end

    context 'when instance ID is a string' do
      before do
        allow(instance).to receive(:id).and_return(instance_id)
        allow(instance).to receive(:read_attribute).with("id").and_return(instance_id)
        allow(instance).to receive(:read_attribute).with(:id).and_return(instance_id)
      end

      context 'when instance ID is UUID' do
        let(:instance_id) { SecureRandom.uuid }

        it 'returns metadata with subject and source information' do
          metadata = instance.send(:cells_claims_default_metadata)

          expect(metadata).to include({
            subject: { type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION, id: instance.id },
            source: {
              type: Cells::Claimable::CLAIMS_SOURCE_TYPE::RAILS_TABLE_ORGANIZATIONS,
              rails_primary_key_id: be_a(String)
            },
            record: instance
          })

          rails_pk_bytes = metadata[:source][:rails_primary_key_id]
          expect(rails_pk_bytes.encoding).to eq(Encoding::ASCII_8BIT)
          expect(rails_pk_bytes.bytesize).to eq(16)
          expect(rails_pk_bytes.unpack1('H*')).to eq(instance_id.delete('-'))
        end
      end

      context 'when instance ID is a string (not uuid)' do
        let(:instance_id) { 'foo/bar' }

        it 'returns metadata with subject and source information' do
          metadata = instance.send(:cells_claims_default_metadata)

          expect(metadata).to include({
            subject: { type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION, id: instance.id },
            source: a_hash_including(
              type: Cells::Claimable::CLAIMS_SOURCE_TYPE::RAILS_TABLE_ORGANIZATIONS,
              rails_primary_key_id: be_a(String)
            ),
            record: instance
          })

          rails_pk_bytes = metadata[:source][:rails_primary_key_id]
          expect(rails_pk_bytes.encoding).to eq(Encoding::UTF_8)
          expect(rails_pk_bytes.bytesize).to eq(7)
          expect(rails_pk_bytes).to eq(instance_id)
        end
      end

      context 'when instance ID is of unsupported type' do
        let(:instance_id) { %w[foo bar] }

        it 'raises error' do
          expect { instance.send(:cells_claims_default_metadata) }.to raise_error(ArgumentError)
        end
      end
    end

    context 'when primary key is missing' do
      before do
        allow(instance).to receive(:read_attribute).with(instance.class.primary_key).and_return(nil)
      end

      it 'raises MissingPrimaryKeyError' do
        expect { instance.send(:cells_claims_default_metadata) }.to raise_error(
          Cells::Claimable::MissingPrimaryKeyError
        )
      end
    end
  end

  describe '#cells_claims_subject_key' do
    subject(:cells_claims_subject_key) { instance.send(:cells_claims_subject_key) }

    context 'when subject_key is a Symbol' do
      let(:subject_key) { :id }

      it 'returns the attribute value' do
        expect(cells_claims_subject_key).to eq(instance.id)
      end
    end

    context 'when subject_key is a Proc' do
      let(:subject_key) { -> { id * 2 } }

      it 'executes the proc and returns the result' do
        expect(cells_claims_subject_key).to eq(instance.id * 2)
      end
    end

    context 'when subject_key is neither Symbol nor Proc' do
      let(:subject_key) { 'invalid' }

      it 'raises ArgumentError' do
        expect { cells_claims_subject_key }.to raise_error(
          ArgumentError, /subject_key must be a Symbol or a Proc, but got: String/
        )
      end
    end
  end

  describe "#handle_grpc_error" do
    let(:model) { build(:organization) }

    context "when error is ALREADY_EXISTS" do
      let(:grpc_error) { GRPC::AlreadyExists.new("conflict") }

      it "assigns attribute-specific message" do
        model.handle_grpc_error(grpc_error)
        expect(model.errors[:base]).to include("path has already been taken")
      end
    end

    context "when error is DEADLINE_EXCEEDED" do
      let(:grpc_error) { GRPC::DeadlineExceeded.new("timeout") }

      it "assigns timeout message" do
        model.handle_grpc_error(grpc_error)
        expect(model.errors[:base]).to include("Request timed out. Please try again.")
      end
    end

    context "when error is unknown" do
      let(:grpc_error) { GRPC::Internal.new("something bad") }

      it "assigns generic message" do
        model.handle_grpc_error(grpc_error)
        expect(model.errors[:base]).to include("An error occurred while processing your request")
      end
    end
  end
end
