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
    let(:invoke_model) { replicator.send(:model) }

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
