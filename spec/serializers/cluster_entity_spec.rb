# frozen_string_literal: true

require 'spec_helper'

describe ClusterEntity do
  describe '#as_json' do
    subject { described_class.new(cluster).as_json }

    context 'when provider type is gcp' do
      let(:cluster) { create(:cluster, provider_type: :gcp, provider_gcp: provider) }

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
      let(:cluster) { create(:cluster, provider_type: :user) }

      it 'has corresponded data' do
        expect(subject[:status]).to eq(:created)
        expect(subject[:status_reason]).to be_nil
      end
    end

    context 'when no application has been installed' do
      let(:cluster) { create(:cluster) }

      subject { described_class.new(cluster).as_json[:applications]}

      it 'contains helm as not_installable' do
        expect(subject).not_to be_empty

        helm = subject[0]
        expect(helm[:name]).to eq('helm')
        expect(helm[:status]).to eq(:not_installable)
      end
    end
  end
end
