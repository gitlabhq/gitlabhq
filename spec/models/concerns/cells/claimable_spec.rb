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

  around do |example|
    example.run
  ensure
    described_class.models_with_claims.delete(test_klass)
  end

  describe 'configuration' do
    it 'retrieves cell configuration' do
      expect(test_klass.cells_claims_subject_type).to eq(Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION)
      expect(test_klass.cells_claims_source_type).to eq(Cells::Claimable::CLAIMS_SOURCE_TYPE::RAILS_TABLE_ORGANIZATIONS)
      expect(test_klass.cells_claims_attributes).to eq(
        path: { type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH,
                feature_flag: :cells_claims_organizations, if: nil }
      )
    end

    it 'derives source_type from table_name when not provided' do
      expect(test_klass.cells_claims_source_type).to eq(
        Gitlab::Cells::TopologyService::Claims::V1::Source::Type::RAILS_TABLE_ORGANIZATIONS
      )
    end

    it 'raises ArgumentError when if: is not a Proc or nil' do
      expect do
        test_klass.cells_claims_attribute :name,
          type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH,
          if: 'not_a_proc'
      end.to raise_error(ArgumentError, %r{must be a Proc/lambda or nil})
    end
  end

  describe 'callbacks' do
    let(:transaction_record) { instance_double(Cells::TransactionRecord) }

    before do
      stub_config_cell(enabled: true)
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

  describe 'conditional claims with if:' do
    let(:conditional_klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'organizations'

        include Cells::Claimable
      end
    end

    let(:transaction_record) { instance_double(Cells::TransactionRecord) }

    before do
      stub_config_cell(enabled: true)
      conditional_klass.cells_claims_attribute :path,
        type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH,
        feature_flag: :cells_claims_organizations,
        if: ->(record) { record.path.exclude?('/') }
      conditional_klass.cells_claims_metadata subject_type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION,
        subject_key: :id
    end

    around do |example|
      example.run
    ensure
      described_class.models_with_claims.delete(conditional_klass)
    end

    describe '#cells_claims_save_changes' do
      context 'when if: returns true' do
        it 'creates a claim' do
          new_instance = conditional_klass.new(path: 'claimable')

          allow(Cells::TransactionRecord)
            .to receive(:current_transaction).with(new_instance.connection).and_return(transaction_record)
          expect(transaction_record).to receive(:create_record).once

          new_instance.save!
        end
      end

      context 'when if: returns false' do
        it 'does not create a claim' do
          new_instance = conditional_klass.new(path: 'group/project')

          allow(Cells::TransactionRecord)
            .to receive(:current_transaction).with(new_instance.connection).and_return(transaction_record)
          expect(transaction_record).not_to receive(:create_record)

          new_instance.save!
        end
      end

      context 'when changing from claimable to non-claimable value' do
        it 'destroys old claim but does not create new claim' do
          record = conditional_klass.create!(path: 'claimtop')

          allow(Cells::TransactionRecord)
            .to receive(:current_transaction).with(record.connection).and_return(transaction_record)
          expect(transaction_record).to receive(:destroy_record).with(
            a_hash_including(bucket: {
              type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH, value: 'claimtop'
            })
          )
          expect(transaction_record).not_to receive(:create_record)

          record.update!(path: 'group/project')
        end
      end

      context 'when changing from non-claimable to claimable value' do
        it 'destroys old claim and creates new claim' do
          record = conditional_klass.create!(path: 'group/project')

          allow(Cells::TransactionRecord)
            .to receive(:current_transaction).with(record.connection).and_return(transaction_record)
          expect(transaction_record).to receive(:destroy_record).with(
            a_hash_including(bucket: {
              type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH, value: 'group/project'
            })
          )
          expect(transaction_record).to receive(:create_record).with(
            a_hash_including(bucket: {
              type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH, value: 'newpath'
            })
          )

          record.update!(path: 'newpath')
        end
      end
    end

    describe '#cells_claims_destroy_changes' do
      context 'when if: returns true' do
        it 'destroys the claim' do
          claimable_instance = conditional_klass.create!(path: 'claimable')

          allow(Cells::TransactionRecord)
            .to receive(:current_transaction).with(claimable_instance.connection).and_return(transaction_record)
          expect(transaction_record).to receive(:destroy_record).with(
            a_hash_including(bucket: {
              type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH, value: 'claimable'
            })
          )

          claimable_instance.destroy!
        end
      end

      context 'when if: returns false' do
        it 'does not destroy the claim' do
          non_claimable_instance = conditional_klass.create!(path: 'group/project')

          allow(Cells::TransactionRecord)
            .to receive(:current_transaction).with(non_claimable_instance.connection).and_return(transaction_record)
          expect(transaction_record).not_to receive(:destroy_record)

          non_claimable_instance.destroy!
        end
      end
    end

    describe '#cells_claims_metadata' do
      context 'when if: returns false' do
        it 'excludes the entry' do
          record = conditional_klass.create!(path: 'group/nested')
          expect(record.cells_claims_metadata).to be_empty
        end
      end

      context 'when if: returns true' do
        it 'includes the entry' do
          record = conditional_klass.create!(path: 'toponly')
          expect(record.cells_claims_metadata).to contain_exactly(
            a_hash_including(bucket: {
              type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH, value: 'toponly'
            })
          )
        end
      end
    end
  end

  describe '.cells_claims_scope' do
    it 'narrows SELECT to claim-relevant columns by default' do
      columns = test_klass.cells_claims_scope.select_values.map(&:to_s)
      expect(columns).to contain_exactly('id', 'updated_at', 'path')
    end

    it 'returns results scoped to the full table by default' do
      instance
      expect(test_klass.cells_claims_scope.to_a).to contain_exactly(instance)
    end

    context 'when subject_key is a Proc' do
      let(:subject_key) { -> { id } }

      it 'skips narrowing because Proc column access cannot be introspected' do
        expect(test_klass.cells_claims_scope.select_values).to be_empty
      end
    end

    context 'when the table has no updated_at column' do
      before do
        allow(test_klass).to receive(:column_names).and_return(%w[id path])
      end

      it 'omits updated_at from the select list' do
        columns = test_klass.cells_claims_scope.select_values.map(&:to_s)
        expect(columns).not_to include('updated_at')
      end
    end

    context 'when overridden' do
      let(:scoped_klass) do
        Class.new(ActiveRecord::Base) do
          self.table_name = 'organizations'

          include Cells::Claimable

          cells_claims_scope do
            where("strpos(path, '/') = 0")
          end
        end
      end

      before do
        scoped_klass.cells_claims_attribute :path,
          type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH,
          feature_flag: :cells_claims_organizations,
          if: ->(record) { record.path.exclude?('/') }
        scoped_klass.cells_claims_metadata subject_type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION,
          subject_key: :id
      end

      around do |example|
        example.run
      ensure
        described_class.models_with_claims.delete(scoped_klass)
      end

      it 'returns only records matching the scope' do
        top_level = scoped_klass.create!(path: 'toplevel')
        scoped_klass.create!(path: 'group/sub')

        result = scoped_klass.cells_claims_scope.to_a
        expect(result).to contain_exactly(top_level)
      end

      it 'narrows SELECT on top of the custom block' do
        columns = scoped_klass.cells_claims_scope.select_values.map(&:to_s)
        expect(columns).to contain_exactly('id', 'updated_at', 'path')
      end
    end
  end

  describe '.models_with_claims' do
    it 'is initialized as an empty Set by default' do
      expect(described_class.models_with_claims).to be_a(Set)
    end

    it 'is never nil' do
      expect(described_class.models_with_claims).not_to be_nil
    end

    it 'includes a model once cells_claims_attribute is called' do
      expect(described_class.models_with_claims).to include(test_klass)
    end

    it 'does not include duplicates when cells_claims_attribute is called multiple times' do
      test_klass.cells_claims_attribute :path, type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH

      expect(described_class.models_with_claims.count(test_klass)).to eq(1)
    end
  end

  describe '#cells_claims_metadata' do
    it 'returns an array of metadata for each registered attribute' do
      metadata = instance.cells_claims_metadata

      expect(metadata.size).to eq(test_klass.cells_claims_attributes.size)
    end

    it 'includes bucket type and value for each attribute' do
      metadata = instance.cells_claims_metadata

      expect(metadata).to include(
        a_hash_including(
          bucket: { type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH,
                    value: instance.path }
        )
      )
    end

    it 'includes subject and source in each entry' do
      metadata = instance.cells_claims_metadata

      expect(metadata).to all(include(
        subject: { type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION, id: instance.id },
        source: a_hash_including(type: Cells::Claimable::CLAIMS_SOURCE_TYPE::RAILS_TABLE_ORGANIZATIONS)
      ))
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

        it 'raises ArgumentError via Cells::Serialization' do
          expect { instance.send(:cells_claims_default_metadata) }.to raise_error(
            ArgumentError, /Unsupported primary key type/
          )
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

  describe '.cells_claims_enabled_for_attribute?' do
    context 'when attribute is not configured' do
      it 'returns false' do
        expect(test_klass.cells_claims_enabled_for_attribute?(:nonexistent)).to be(false)
      end
    end

    context 'when feature_flag is nil' do
      before do
        stub_config_cell(enabled: true)
      end

      it 'returns true' do
        test_klass.cells_claims_attribute :no_flag_attr,
          type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH

        expect(test_klass.cells_claims_enabled_for_attribute?(:no_flag_attr)).to be(true)
      end
    end

    context 'when cell config is disabled' do
      before do
        stub_config_cell(enabled: false)
      end

      it 'returns false' do
        expect(test_klass.cells_claims_enabled_for_attribute?(:path)).to be(false)
      end
    end

    context 'when cell config is enabled' do
      before do
        stub_config_cell(enabled: true)
      end

      context 'when feature flag is enabled' do
        it 'returns true' do
          expect(test_klass.cells_claims_enabled_for_attribute?(:path)).to be(true)
        end
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(cells_claims_organizations: false)
        end

        it 'returns false' do
          expect(test_klass.cells_claims_enabled_for_attribute?(:path)).to be(false)
        end
      end
    end
  end

  describe '#build_destroy_metadata_for_worker' do
    context 'when attribute is not configured' do
      it 'returns nil' do
        expect(instance.build_destroy_metadata_for_worker(:nonexistent)).to be_nil
      end
    end

    context 'when attribute is configured and claimable' do
      it 'returns a JSON-serializable hash with all metadata' do
        metadata = instance.build_destroy_metadata_for_worker(:path)

        expect(metadata).to eq({
          'bucket_type' => Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH,
          'bucket_value' => instance.path,
          'subject_type' => Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION,
          'subject_id' => instance.id,
          'source_type' => Cells::Claimable::CLAIMS_SOURCE_TYPE::RAILS_TABLE_ORGANIZATIONS,
          'primary_key' => instance.id
        })
      end
    end

    context 'when if: condition returns false' do
      let(:conditional_klass) do
        Class.new(ActiveRecord::Base) do
          self.table_name = 'organizations'
          include Cells::Claimable
        end
      end

      let(:conditional_instance) { conditional_klass.create!(path: 'group/nested') }

      before do
        conditional_klass.cells_claims_attribute :path,
          type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH,
          feature_flag: :cells_claims_organizations,
          if: ->(record) { record.path.exclude?('/') }
        conditional_klass.cells_claims_metadata subject_type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION,
          subject_key: :id
      end

      after do
        described_class.models_with_claims.delete(conditional_klass)
      end

      it 'returns nil' do
        expect(conditional_instance.build_destroy_metadata_for_worker(:path)).to be_nil
      end
    end
  end

  describe '#cells_claims_metadata_for_attribute' do
    context 'when attribute is not configured' do
      it 'returns nil' do
        expect(instance.cells_claims_metadata_for_attribute(:nonexistent)).to be_nil
      end
    end

    context 'when attribute is configured with an if: condition that returns false' do
      let(:conditional_klass) do
        Class.new(ActiveRecord::Base) do
          self.table_name = 'organizations'
          include Cells::Claimable
        end
      end

      let(:conditional_instance) { conditional_klass.create!(path: 'group/nested') }

      before do
        conditional_klass.cells_claims_attribute :path,
          type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH,
          feature_flag: :cells_claims_organizations,
          if: ->(record) { record.path.exclude?('/') }
        conditional_klass.cells_claims_metadata subject_type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION,
          subject_key: :id
      end

      after do
        described_class.models_with_claims.delete(conditional_klass)
      end

      it 'returns nil' do
        expect(conditional_instance.cells_claims_metadata_for_attribute(:path)).to be_nil
      end
    end

    context 'when attribute is configured and claimable' do
      it 'returns the claim metadata' do
        metadata = instance.cells_claims_metadata_for_attribute(:path)

        expect(metadata).to include(
          bucket: { type: Cells::Claimable::CLAIMS_BUCKET_TYPE::ORGANIZATION_PATH, value: instance.path },
          subject: { type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::ORGANIZATION, id: instance.id }
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
