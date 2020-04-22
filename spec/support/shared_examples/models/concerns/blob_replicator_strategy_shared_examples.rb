# frozen_string_literal: true

# Include these shared examples in specs of Replicators that include
# BlobReplicatorStrategy.
#
# A let variable called model_record should be defined in the spec. It should be
# a valid, unpersisted instance of the model class.
#
RSpec.shared_examples 'a blob replicator' do
  include EE::GeoHelpers

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }

  subject(:replicator) { model_record.replicator }

  before do
    stub_current_geo_node(primary)
  end

  describe '#handle_after_create_commit' do
    it 'creates a Geo::Event' do
      expect do
        replicator.handle_after_create_commit
      end.to change { ::Geo::Event.count }.by(1)

      expect(::Geo::Event.last.attributes).to include(
        "replicable_name" => replicator.replicable_name, "event_name" => "created", "payload" => { "model_record_id" => replicator.model_record.id })
    end

    it 'schedules the checksum calculation if needed' do
      expect(Geo::BlobVerificationPrimaryWorker).to receive(:perform_async)
      expect(replicator).to receive(:needs_checksum?).and_return(true)

      replicator.handle_after_create_commit
    end

    it 'does not schedule the checksum calculation if feature flag is disabled' do
      stub_feature_flags(geo_self_service_framework: false)

      expect(Geo::BlobVerificationPrimaryWorker).not_to receive(:perform_async)
      allow(replicator).to receive(:needs_checksum?).and_return(true)

      replicator.handle_after_create_commit
    end
  end

  describe '#calculate_checksum!' do
    it 'calculates the checksum' do
      model_record.save!

      replicator.calculate_checksum!

      expect(model_record.reload.verification_checksum).not_to be_nil
      expect(model_record.reload.verified_at).not_to be_nil
    end

    it 'saves the error message and increments retry counter' do
      model_record.save!

      allow(model_record).to receive(:calculate_checksum!) do
        raise StandardError.new('Failure to calculate checksum')
      end

      replicator.calculate_checksum!

      expect(model_record.reload.verification_failure).to eq 'Failure to calculate checksum'
      expect(model_record.verification_retry_count).to be 1
    end
  end

  describe '#consume_created_event' do
    it 'invokes Geo::BlobDownloadService' do
      service = double(:service)

      expect(service).to receive(:execute)
      expect(::Geo::BlobDownloadService).to receive(:new).with(replicator: replicator).and_return(service)

      replicator.consume_created_event
    end
  end

  describe '#carrierwave_uploader' do
    it 'is implemented' do
      expect do
        replicator.carrierwave_uploader
      end.not_to raise_error
    end
  end

  describe '#model' do
    let(:invoke_model) { replicator.class.model }

    it 'is implemented' do
      expect do
        invoke_model
      end.not_to raise_error
    end

    it 'is a Class' do
      expect(invoke_model).to be_a(Class)
    end

    # For convenience (and reliability), instead of asking developers to include shared examples on each model spec as well
    context 'replicable model' do
      it 'defines #replicator' do
        expect(model_record).to respond_to(:replicator)
      end

      it 'invokes replicator.handle_after_create_commit on create' do
        expect(replicator).to receive(:handle_after_create_commit)

        model_record.save!
      end
    end
  end
end
