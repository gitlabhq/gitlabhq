# frozen_string_literal: true

RSpec.shared_examples 'creating new claims' do |factory_name:|
  let!(:instance) { build(factory_name) }
  let(:claim_service) { Gitlab::TopologyServiceClient::ClaimService.instance }
  let(:deadline) { 10.seconds.from_now.to_i }
  let(:lease_uuid) { SecureRandom.uuid }
  let(:fake_error) { Class.new(RuntimeError) }
  let(:claims_records) { claims_records_for(instance) }
  let(:create_records) { [] }
  let(:destroy_records) { [] }

  def claims_records_for(instance, only: {})
    instance.class.cells_claims_attributes.filter_map do |attribute, config|
      value = only[attribute]

      if only.empty? || value # rubocop:disable Style/IfUnlessModifier -- I think this is easier to read
        claims_records_attribute_for(attribute, config, value)
      end
    end
  end

  def claims_records_attribute_for(attribute, config, value)
    instance.__send__(
      :cells_claims_metadata_for,
      config[:type],
      value || instance.public_send(attribute))
  end

  before do
    allow(Gitlab.config.cell).to receive(:enabled).and_return(true)
    allow(Current).to receive(:cells_claims_leases?).and_return(true)

    allow(GRPC::Core::TimeConsts).to receive(:from_relative_time)
      .and_return(deadline)
  end

  context 'when creating the record' do
    let(:create_records) { claims_records }

    it 'claims attributes cleanly when created' do
      expect_begin_update(:save)
      expect_commit_update

      expect(instance.save).to be(true)
      expect(Cells::OutstandingLease.count).to eq(0)
    end

    context 'when begin_update fails' do
      it 'does not save anything' do
        expect_begin_update(:save, success: false)

        expect { instance.save }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already
        expect(instance.class.count).to eq(0)
        expect(Cells::OutstandingLease.count).to eq(0)
      end
    end

    context 'when begin_update is successful but failing to commit' do
      it 'rolls back the lease created from begin_update' do
        expect_begin_update(:save)
        expect_abort_commit
        expect_rollback_update

        expect { instance.save }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already
        expect(instance.class.count).to eq(0)
        expect(Cells::OutstandingLease.count).to eq(0)
      end
    end

    context 'when commit_update fails' do
      it 'saves instance but leaves the outstanding lease' do
        expect_begin_update(:save)
        expect_commit_update(success: false)

        expect { instance.save }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already
        expect(instance.class.count).to eq(1)
        expect(Cells::OutstandingLease.count).to eq(1)
      end
    end
  end

  context 'when deleting the record' do
    let!(:instance) { create(factory_name) } # rubocop:disable Rails/SaveBang -- This is a factory, there's no bang equivalent
    let(:destroy_records) { claims_records }

    it 'deletes the claimed attributes cleanly when created' do
      expect_begin_update(:destroy)
      expect_commit_update

      instance.destroy!
      expect(instance.destroyed?).to be(true)
      expect(Cells::OutstandingLease.count).to eq(0)
    end

    context 'when begin_update fails' do
      it 'does not delete anything' do
        expect_begin_update(:destroy, success: false)

        expect { instance.destroy }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already
        expect(instance.destroyed?).to be(false)
        expect(instance.class.count).to eq(1)
        expect(Cells::OutstandingLease.count).to eq(0)
      end
    end

    context 'when begin_update is successful but failing to commit' do
      it 'rolls back the lease created from begin_update' do
        expect_begin_update(:destroy)
        expect_abort_commit
        expect_rollback_update

        expect { instance.destroy }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already
        expect(instance.destroyed?).to be(false)
        expect(instance.class.count).to eq(1)
        expect(Cells::OutstandingLease.count).to eq(0)
      end
    end

    context 'when commit_update fails' do
      it 'deletes record but leaves the outstanding lease' do
        expect_begin_update(:destroy)
        expect_commit_update(success: false)

        expect { instance.destroy }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already
        expect(instance.class.count).to eq(0)
        expect(Cells::OutstandingLease.count).to eq(1)
      end
    end
  end

  context 'when updating the record' do
    let!(:instance) { create(factory_name) } # rubocop:disable Rails/SaveBang -- This is a factory, there's no bang equivalent

    let!(:destroy_records) do
      claims_records_for(instance, only: original_attributes)
    end

    let!(:create_records) do
      claims_records_for(instance, only: transform_attributes)
    end

    let(:original_attributes) do
      transform_attributes.each_key.index_with do |key|
        instance.public_send(key)
      end
    end

    it 'updates the claimed attributes cleanly when saved' do
      expect_begin_update(:save)
      expect_commit_update

      expect(instance.update!(transform_attributes)).to be(true)
      expect(Cells::OutstandingLease.count).to eq(0)
    end

    context 'when begin_update fails' do
      it 'does not save anything' do
        expect_begin_update(:save, success: false)

        expect { instance.update(transform_attributes) }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already

        instance.reload
        original_attributes.each do |key, value|
          expect(instance.public_send(key)).to eq(value)
        end

        expect(Cells::OutstandingLease.count).to eq(0)
      end
    end

    context 'when begin_update is successful but failing to commit' do
      it 'rolls back the lease created from begin_update' do
        expect_begin_update(:save)
        expect_abort_commit
        expect_rollback_update

        expect { instance.update(transform_attributes) }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already

        instance.reload
        original_attributes.each do |key, value|
          expect(instance.public_send(key)).to eq(value)
        end

        expect(Cells::OutstandingLease.count).to eq(0)
      end
    end

    context 'when commit_update fails' do
      it 'updates attributes but leaves the outstanding lease' do
        expect_begin_update(:save)
        expect_commit_update(success: false)

        expect { instance.update(transform_attributes) }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already

        instance.reload
        transform_attributes.each do |key, value|
          expect(instance.public_send(key)).to eq(value)
        end

        expect(Cells::OutstandingLease.count).to eq(1)
      end
    end
  end

  def expect_begin_update(type, success: true)
    allow(instance).to receive(:"cells_claims_#{type}_changes")
      .and_wrap_original do |original, *args|
        # We delay defining this mock because only after saving we have
        # the id we can use for the metadata.
        mock = expect(claim_service).to receive(:begin_update).with(
          Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateRequest.new(
            create_records: create_records,
            destroy_records: destroy_records,
            cell_id: claim_service.cell_id
          ),
          deadline: deadline
        )

        if success
          mock.and_return(
            Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateResponse.new(
              lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(
                value: lease_uuid)))
        else
          mock.and_raise(fake_error.new)
        end

        original.call(*args)
      end
  end

  def expect_commit_update(success: true)
    mock = expect(claim_service).to receive(:commit_update).with(
      Gitlab::Cells::TopologyService::Claims::V1::CommitUpdateRequest.new(
        lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(
          value: lease_uuid),
        cell_id: claim_service.cell_id),
      deadline: deadline
    )

    mock.and_raise(fake_error.new) unless success
  end

  def expect_rollback_update
    expect(claim_service).to receive(:rollback_update).with(
      Gitlab::Cells::TopologyService::Claims::V1::RollbackUpdateRequest.new(
        lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(
          value: lease_uuid),
        cell_id: claim_service.cell_id),
      deadline: deadline
    )
  end

  def expect_abort_commit
    expect_next_instance_of(Cells::TransactionRecord) do |record|
      expect(record).to receive(:before_committed!)
        .and_wrap_original do |original_method, *args|
          original_method.call(*args)
          raise fake_error, 'Abort commit'
        end
    end
  end
end
