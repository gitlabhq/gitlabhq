require 'rails_helper'

describe Clusters::Applications::Knative do
  let(:knative) { create(:clusters_applications_knative, hostname: 'example.com') }

  include_examples 'cluster application core specs', :clusters_applications_knative

  describe '#status' do
    let(:cluster) { create(:cluster, :provided_by_gcp) }

    subject { described_class.new(cluster: cluster) }

    it 'sets a default status' do
      expect(subject.status_name).to be(:not_installable)
    end

    context 'when application helm is scheduled' do
      before do
        create(:clusters_applications_helm, :scheduled, cluster: cluster)
      end

      it 'defaults to :not_installable' do
        expect(subject.status_name).to be(:not_installable)
      end
    end

    context 'when application is scheduled' do
      before do
        create(:clusters_applications_helm, :installed, cluster: cluster)
      end

      it 'sets a default status' do
        expect(subject.status_name).to be(:installable)
      end
    end
  end

  describe 'status state machine' do
    describe '#make_installing' do
      subject { create(:clusters_applications_knative, :scheduled, hostname: 'example.com') }

      it 'is installing' do
        subject.make_installing!

        expect(subject).to be_installing
      end
    end

    describe '#make_installed' do
      subject { create(:clusters_applications_knative, :installing, hostname: 'example.com') }

      it 'is installed' do
        subject.make_installed

        expect(subject).to be_installed
      end
    end

    describe '#make_errored' do
      subject { create(:clusters_applications_knative, :installing, hostname: 'example.com') }
      let(:reason) { 'some errors' }

      it 'is errored' do
        subject.make_errored(reason)

        expect(subject).to be_errored
        expect(subject.status_reason).to eq(reason)
      end
    end
    describe '#make_scheduled' do
      subject { create(:clusters_applications_knative, :installable, hostname: 'example.com') }

      it 'is scheduled' do
        subject.make_scheduled

        expect(subject).to be_scheduled
      end

      describe 'when was errored' do
        subject { create(:clusters_applications_knative, :errored, hostname: 'example.com') }

        it 'clears #status_reason' do
          expect(subject.status_reason).not_to be_nil

          subject.make_scheduled!

          expect(subject.status_reason).to be_nil
        end
      end
    end
  end

  describe '#available?' do
    using RSpec::Parameterized::TableSyntax

    where(:trait, :available) do
      :not_installable  | false
      :installable      | false
      :scheduled        | false
      :installing       | false
      :installed        | true
      :updating         | false
      :updated          | true
      :errored          | false
      :update_errored   | false
      :timeouted        | false
    end

    with_them do
      subject { build(:clusters_applications_knative, trait) }

      if params[:available]
        it { is_expected.to be_available }
      else
        it { is_expected.not_to be_available }
      end
    end
  end

  describe '.installed' do
    subject { described_class.installed }

    let!(:cluster) { create(:clusters_applications_knative, :installed, hostname: 'example.com') }

    before do
      create(:clusters_applications_knative, :errored, hostname: 'example.com')
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '#make_installing!' do
    before do
      application.make_installing!
    end

    context 'application install previously errored with older version' do
      let(:application) { create(:clusters_applications_knative, :scheduled, version: '0.1.3', hostname: 'example.com') }

      it 'updates the application version' do
        expect(application.reload.version).to eq('0.1.3')
      end
    end
  end

  describe '#make_installed' do
    subject { described_class.installed }

    let!(:cluster) { create(:clusters_applications_knative, :installed, hostname: 'example.com') }

    before do
      create(:clusters_applications_knative, :errored, hostname: 'example.com')
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '#install_command' do
    subject { knative.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'should be initialized with knative arguments' do
      expect(subject.name).to eq('knative')
      expect(subject.chart).to eq('knative/knative')
      expect(subject.version).to eq('0.1.3')
      expect(subject.files).to eq(knative.files)
    end

    context 'application failed to install previously' do
      let(:knative) { create(:clusters_applications_knative, :errored, version: 'knative', hostname: 'example.com') }

      it 'should be initialized with the locked version' do
        expect(subject.version).to eq('0.1.3')
      end
    end
  end

  describe '#files' do
    let(:application) { knative }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'should include knative valid keys in values' do
      expect(values).to include('domain')
    end

    context 'when the helm application does not have a ca_cert' do
      before do
        application.cluster.application_helm.ca_cert = nil
      end

      it 'should not include cert files' do
        expect(subject[:'ca.pem']).not_to be_present
        expect(subject[:'cert.pem']).not_to be_present
        expect(subject[:'key.pem']).not_to be_present
      end
    end

    it 'should include cert files' do
      expect(subject[:'ca.pem']).to be_present
      expect(subject[:'ca.pem']).to eq(application.cluster.application_helm.ca_cert)

      expect(subject[:'cert.pem']).to be_present
      expect(subject[:'key.pem']).to be_present

      cert = OpenSSL::X509::Certificate.new(subject[:'cert.pem'])
      expect(cert.not_after).to be < 60.minutes.from_now
    end
  end
end
