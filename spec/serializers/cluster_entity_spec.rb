# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClusterEntity do
  include Gitlab::Routing.url_helpers

  describe '#as_json' do
    let(:user) { nil }
    let(:request) { EntityRequest.new({ current_user: user }) }

    subject { described_class.new(cluster, request: request).as_json }

    context 'when provider type is gcp' do
      let(:cluster) { create(:cluster, :instance, provider_type: :gcp, provider_gcp: provider) }

      context 'when status is creating' do
        let(:provider) { create(:cluster_provider_gcp, :creating) }

        it 'has corresponded data' do
          expect(subject[:status]).to eq(:creating)
          expect(subject[:status_reason]).to be_nil
        end
      end

      context 'when status is errored' do
        let(:provider) { create(:cluster_provider_gcp, :errored) }

        it 'has corresponded data' do
          expect(subject[:status]).to eq(:errored)
          expect(subject[:status_reason]).to eq(provider.status_reason)
        end
      end
    end

    context 'when provider type is user' do
      let(:cluster) { create(:cluster, :instance, provider_type: :user) }

      it 'has corresponded data' do
        expect(subject[:status]).to eq(:created)
        expect(subject[:status_reason]).to be_nil
      end
    end
  end
end
