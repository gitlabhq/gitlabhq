# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClusterSerializer do
  let(:cluster) { create(:cluster, :project, provider_type: :user) }

  describe '#represent_list' do
    subject { described_class.new(current_user: nil).represent_list(cluster).keys }

    it 'serializes attrs correctly' do
      is_expected.to contain_exactly(
        :cluster_type,
        :enabled,
        :environment_scope,
        :id,
        :kubernetes_errors,
        :name,
        :nodes,
        :path,
        :provider_type,
        :status)
    end
  end

  describe '#represent_status' do
    subject { described_class.new(current_user: nil).represent_status(cluster).keys }

    context 'when provider type is gcp and cluster is errored' do
      let(:cluster) do
        errored_provider = create(:cluster_provider_gcp, :errored)

        create(:cluster, provider_type: :gcp, provider_gcp: errored_provider)
      end

      it 'serializes attrs correctly' do
        is_expected.to contain_exactly(:status, :status_reason)
      end
    end

    context 'when provider type is user' do
      it 'serializes attrs correctly' do
        is_expected.to contain_exactly(:status, :status_reason)
      end
    end
  end
end
