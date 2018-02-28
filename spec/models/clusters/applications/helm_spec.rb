require 'rails_helper'

describe Clusters::Applications::Helm do
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to validate_presence_of(:cluster) }

  describe '#name' do
    it 'is .application_name' do
      expect(subject.name).to eq(described_class.application_name)
    end

    it 'is recorded in Clusters::Cluster::APPLICATIONS' do
      expect(Clusters::Cluster::APPLICATIONS[subject.name]).to eq(described_class)
    end
  end

  describe '#version' do
    it 'defaults to Gitlab::Kubernetes::Helm::HELM_VERSION' do
      expect(subject.version).to eq(Gitlab::Kubernetes::Helm::HELM_VERSION)
    end
  end

  describe '#status' do
    let(:cluster) { create(:cluster) }

    subject { described_class.new(cluster: cluster) }

    it 'defaults to :not_installable' do
      expect(subject.status_name).to be(:not_installable)
    end

    context 'when platform kubernetes is defined' do
      let(:cluster) { create(:cluster, :provided_by_gcp) }

      it 'defaults to :installable' do
        expect(subject.status_name).to be(:installable)
      end
    end
  end

  describe '#install_command' do
    it 'has all the needed information' do
      expect(subject.install_command).to have_attributes(name: subject.name, install_helm: true)
    end
  end

  describe 'status state machine' do
    describe '#make_installing' do
      subject { create(:clusters_applications_helm, :scheduled) }

      it 'is installing' do
        subject.make_installing!

        expect(subject).to be_installing
      end
    end

    describe '#make_installed' do
      subject { create(:clusters_applications_helm, :installing) }

      it 'is installed' do
        subject.make_installed

        expect(subject).to be_installed
      end
    end

    describe '#make_errored' do
      subject { create(:clusters_applications_helm, :installing) }
      let(:reason) { 'some errors' }

      it 'is errored' do
        subject.make_errored(reason)

        expect(subject).to be_errored
        expect(subject.status_reason).to eq(reason)
      end
    end

    describe '#make_scheduled' do
      subject { create(:clusters_applications_helm, :installable) }

      it 'is scheduled' do
        subject.make_scheduled

        expect(subject).to be_scheduled
      end

      describe 'when was errored' do
        subject { create(:clusters_applications_helm, :errored) }

        it 'clears #status_reason' do
          expect(subject.status_reason).not_to be_nil

          subject.make_scheduled!

          expect(subject.status_reason).to be_nil
        end
      end
    end
  end
end
