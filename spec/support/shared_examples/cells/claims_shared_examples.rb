# frozen_string_literal: true

RSpec.shared_examples 'creating new claims' do |factory_name:|
  subject! { build(factory_name) }

  let(:claim_service) { Gitlab::TopologyServiceClient::ClaimService.instance }
  let(:deadline) { 10.seconds.from_now.to_i }
  let(:lease_uuid) { SecureRandom.uuid }
  let(:fake_error) { Class.new(RuntimeError) }
  let(:create_records) { [] }
  let(:destroy_records) { [] }

  def claims_records(only: {})
    claims_records_for(subject, only: only)
  end

  def claims_records_for(instance, only: {})
    instance.class.cells_claims_attributes.filter_map do |attribute, config|
      value = only[attribute]

      if only.empty? || value # rubocop:disable Style/IfUnlessModifier -- I think this is easier to read
        claims_records_attribute_for(instance, attribute, config, value)
      end
    end
  end

  def claims_records_attribute_for(instance, attribute, config, value)
    instance.__send__(
      :cells_claims_metadata_for,
      config[:type],
      value || instance.public_send(attribute))
  end

  before do
    stub_config_cell(enabled: true)
    allow(Current).to receive(:cells_claims_leases?).and_return(true)

    allow(GRPC::Core::TimeConsts).to receive(:from_relative_time)
      .and_return(deadline)
  end

  context 'when creating the record' do
    let(:create_records) { claims_records }

    it 'claims attributes cleanly when created' do
      expect_begin_update(:save)
      expect_commit_update

      expect(subject.save).to be(true)
      expect(Cells::OutstandingLease.count).to eq(0)
    end

    context 'when begin_update fails' do
      it 'does not save anything' do
        expect_begin_update(:save, success: false)

        expect { subject.save }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already
        expect(subject.class.count).to eq(0)
        expect(Cells::OutstandingLease.count).to eq(0)
      end
    end

    context 'when begin_update is successful but failing to commit' do
      it 'rolls back the lease created from begin_update' do
        expect_begin_update(:save)
        expect_abort_commit
        expect_rollback_update

        expect { subject.save }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already
        expect(subject.class.count).to eq(0)
        expect(Cells::OutstandingLease.count).to eq(0)
      end
    end

    context 'when commit_update fails' do
      it 'saves subject but leaves the outstanding lease' do
        expect_begin_update(:save)
        expect_commit_update(success: false)

        expect { subject.save }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already
        expect(subject.class.count).to eq(1)
        expect(Cells::OutstandingLease.count).to eq(1)
      end
    end
  end

  context 'when deleting the record' do
    subject! { super().tap(&:save!) }

    let(:destroy_records) { claims_records }

    it 'deletes the claimed attributes cleanly when created' do
      expect_begin_update(:destroy)
      expect_commit_update

      subject.destroy!
      expect(subject.destroyed?).to be(true)
      expect(Cells::OutstandingLease.count).to eq(0)
    end

    context 'when begin_update fails' do
      it 'does not delete anything' do
        expect_begin_update(:destroy, success: false)

        expect { subject.destroy }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already
        expect(subject.destroyed?).to be(false)
        expect(subject.class.count).to eq(1)
        expect(Cells::OutstandingLease.count).to eq(0)
      end
    end

    context 'when begin_update is successful but failing to commit' do
      it 'rolls back the lease created from begin_update' do
        expect_begin_update(:destroy)
        expect_abort_commit
        expect_rollback_update

        expect { subject.destroy }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already
        expect(subject.destroyed?).to be(false)
        expect(subject.class.count).to eq(1)
        expect(Cells::OutstandingLease.count).to eq(0)
      end
    end

    context 'when commit_update fails' do
      it 'deletes record but leaves the outstanding lease' do
        expect_begin_update(:destroy)
        expect_commit_update(success: false)

        expect { subject.destroy }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already
        expect(subject.class.count).to eq(0)
        expect(Cells::OutstandingLease.count).to eq(1)
      end
    end
  end

  context 'when updating the record' do
    subject! { super().tap(&:save!) }

    let!(:destroy_records) { claims_records(only: original_attributes) }
    let!(:create_records) { claims_records(only: transform_attributes) }

    let(:original_attributes) do
      transform_attributes.each_key.index_with do |key|
        subject.public_send(key)
      end
    end

    it 'updates the claimed attributes cleanly when saved' do
      expect_begin_update(:save)
      expect_commit_update

      expect(subject.update!(transform_attributes)).to be(true)
      expect(Cells::OutstandingLease.count).to eq(0)
    end

    context 'when begin_update fails' do
      it 'does not save anything' do
        expect_begin_update(:save, success: false)

        expect { subject.update(transform_attributes) }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already

        subject.reload
        original_attributes.each do |key, value|
          expect(subject.public_send(key)).to eq(value)
        end

        expect(Cells::OutstandingLease.count).to eq(0)
      end
    end

    context 'when begin_update is successful but failing to commit' do
      it 'rolls back the lease created from begin_update' do
        expect_begin_update(:save)
        expect_abort_commit
        expect_rollback_update

        expect { subject.update(transform_attributes) }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already

        subject.reload
        original_attributes.each do |key, value|
          expect(subject.public_send(key)).to eq(value)
        end

        expect(Cells::OutstandingLease.count).to eq(0)
      end
    end

    context 'when commit_update fails' do
      it 'updates attributes but leaves the outstanding lease' do
        expect_begin_update(:save)
        expect_commit_update(success: false)

        expect { subject.update(transform_attributes) }.to raise_error(fake_error) # rubocop:disable Rails/SaveBang -- We're checking exceptions already

        subject.reload
        transform_attributes.each do |key, value|
          expect(subject.public_send(key)).to eq(value)
        end

        expect(Cells::OutstandingLease.count).to eq(1)
      end
    end
  end

  def expect_begin_update(type, success: true)
    allow(Cells::OutstandingLease).to receive(:create_from_request!)
      .and_wrap_original do |original, *args|
        actual_create_records = args.dig(0, :create_records)
        actual_destroy_records = args.dig(0, :destroy_records)
        # This way we ignore the orders for the records
        original.call(
          create_records: sort_records(actual_create_records),
          destroy_records: sort_records(actual_destroy_records),
          deadline: args.dig(0, :deadline)
        )
      end

    allow(subject).to receive(:"cells_claims_#{type}_changes")
      .and_wrap_original do |original, *args|
        # We delay defining this mock because only after saving we have
        # the id we can use for the metadata.
        mock = expect(claim_service).to receive(:begin_update).with(
          Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateRequest.new(
            create_records: sort_records(create_records),
            destroy_records: sort_records(destroy_records),
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

  def sort_records(records)
    # We don't care about the actual order, but need a consistent order
    # within this test run, so that when we compare two arrays we're only
    # checking that they contain the same records regardless of order.
    # This is reliable unless we hit hash collisions, which could cause
    # test flakiness.
    records.sort_by(&:hash)
  end
end
