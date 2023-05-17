# frozen_string_literal: true

RSpec.shared_examples 'database events tracking' do
  describe 'events tracking' do
    # required definitions:
    # :record, :update_params
    #
    # other available attributes:
    # :project, :namespace

    let(:user) { nil }
    let(:category) { described_class.to_s }
    let(:label) { described_class.table_name }
    let(:action) { "database_event_#{property}" }
    let(:feature_flag_name) { :product_intelligence_database_event_tracking }
    let(:record_tracked_attributes) { record.attributes.slice(*described_class::SNOWPLOW_ATTRIBUTES.map(&:to_s)) }
    let(:base_extra) { record_tracked_attributes.merge(project: try(:project), namespace: try(:namespace)) }

    before do
      allow(Gitlab::Tracking).to receive(:database_event).and_call_original
    end

    describe '#create' do
      it_behaves_like 'Snowplow event tracking', overrides: { tracking_method: :database_event } do
        subject(:create_record) { record }

        let(:extra) { base_extra }
        let(:property) { 'create' }
      end
    end

    describe '#update', :freeze_time do
      it_behaves_like 'Snowplow event tracking', overrides: { tracking_method: :database_event } do
        subject(:update_record) { record.update!(update_params) }

        let(:extra) { base_extra.merge(update_params.stringify_keys) }
        let(:property) { 'update' }
      end
    end

    describe '#destroy' do
      it_behaves_like 'Snowplow event tracking', overrides: { tracking_method: :database_event } do
        subject(:delete_record) { record.destroy! }

        let(:extra) { base_extra }
        let(:property) { 'destroy' }
      end
    end
  end
end

RSpec.shared_examples 'database events tracking batch 2' do
  it_behaves_like 'database events tracking' do
    let(:feature_flag_name) { :product_intelligence_database_event_tracking_batch2 }
  end
end
