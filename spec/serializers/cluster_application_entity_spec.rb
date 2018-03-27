require 'spec_helper'

describe ClusterApplicationEntity do
  describe '#as_json' do
    let(:application) { build(:clusters_applications_helm) }
    subject { described_class.new(application).as_json }

    it 'has name' do
      expect(subject[:name]).to eq(application.name)
    end

    it 'has status' do
      expect(subject[:status]).to eq(:not_installable)
    end

    it 'has no status_reason' do
      expect(subject[:status_reason]).to be_nil
    end

    context 'when application is errored' do
      let(:application) { build(:clusters_applications_helm, :errored) }

      it 'has corresponded data' do
        expect(subject[:status]).to eq(:errored)
        expect(subject[:status_reason]).not_to be_nil
        expect(subject[:status_reason]).to eq(application.status_reason)
      end
    end

    context 'for ingress application' do
      let(:application) do
        build(
          :clusters_applications_ingress,
          :installed,
          external_ip: '111.222.111.222'
        )
      end

      it 'includes external_ip' do
        expect(subject[:external_ip]).to eq('111.222.111.222')
      end
    end
  end
end
