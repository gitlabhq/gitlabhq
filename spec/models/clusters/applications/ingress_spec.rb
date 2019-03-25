require 'rails_helper'

describe Clusters::Applications::Ingress do
  let(:ingress) { create(:clusters_applications_ingress) }

  it_behaves_like 'having unique enum values'

  include_examples 'cluster application core specs', :clusters_applications_ingress
  include_examples 'cluster application status specs', :clusters_applications_ingress
  include_examples 'cluster application version specs', :clusters_applications_ingress
  include_examples 'cluster application helm specs', :clusters_applications_ingress
  include_examples 'cluster application initial status specs'

  before do
    allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_in)
    allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_async)
  end

  describe '#make_installed!' do
    before do
      application.make_installed!
    end

    let(:application) { create(:clusters_applications_ingress, :installing) }

    it 'schedules a ClusterWaitForIngressIpAddressWorker' do
      expect(ClusterWaitForIngressIpAddressWorker).to have_received(:perform_in)
        .with(Clusters::Applications::Ingress::FETCH_IP_ADDRESS_DELAY, 'ingress', application.id)
    end
  end

  describe '#schedule_status_update' do
    let(:application) { create(:clusters_applications_ingress, :installed) }

    before do
      application.schedule_status_update
    end

    it 'schedules a ClusterWaitForIngressIpAddressWorker' do
      expect(ClusterWaitForIngressIpAddressWorker).to have_received(:perform_async)
        .with('ingress', application.id)
    end

    context 'when the application is not installed' do
      let(:application) { create(:clusters_applications_ingress, :installing) }

      it 'does not schedule a ClusterWaitForIngressIpAddressWorker' do
        expect(ClusterWaitForIngressIpAddressWorker).not_to have_received(:perform_async)
      end
    end

    context 'when there is already an external_ip' do
      let(:application) { create(:clusters_applications_ingress, :installed, external_ip: '111.222.222.111') }

      it 'does not schedule a ClusterWaitForIngressIpAddressWorker' do
        expect(ClusterWaitForIngressIpAddressWorker).not_to have_received(:perform_in)
      end
    end

    context 'when there is already an external_hostname' do
      let(:application) { create(:clusters_applications_ingress, :installed, external_hostname: 'localhost.localdomain') }

      it 'does not schedule a ClusterWaitForIngressIpAddressWorker' do
        expect(ClusterWaitForIngressIpAddressWorker).not_to have_received(:perform_in)
      end
    end
  end

  describe '#install_command' do
    subject { ingress.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'should be initialized with ingress arguments' do
      expect(subject.name).to eq('ingress')
      expect(subject.chart).to eq('stable/nginx-ingress')
      expect(subject.version).to eq('1.1.2')
      expect(subject).to be_rbac
      expect(subject.files).to eq(ingress.files)
    end

    context 'on a non rbac enabled cluster' do
      before do
        ingress.cluster.platform_kubernetes.abac!
      end

      it { is_expected.not_to be_rbac }
    end

    context 'application failed to install previously' do
      let(:ingress) { create(:clusters_applications_ingress, :errored, version: 'nginx') }

      it 'should be initialized with the locked version' do
        expect(subject.version).to eq('1.1.2')
      end
    end
  end

  describe '#upgrade_command' do
    let(:ingress) { build(:clusters_applications_ingress) }
    let(:values) { ingress.values }

    it 'returns an instance of Gitlab::Kubernetes::Helm::InstallCommand' do
      expect(ingress.upgrade_command(values)).to be_an_instance_of(::Gitlab::Kubernetes::Helm::InstallCommand)
    end

    it 'should be initialized with ingress arguments' do
      command = ingress.upgrade_command(values)

      expect(command.name).to eq('ingress')
      expect(command.chart).to eq('stable/nginx-ingress')
      expect(command.version).to eq('1.1.2')
      expect(command.files).to eq(ingress.files)
    end
  end

  describe '#update_in_progress?' do
    context 'when app is updating' do
      it 'returns true' do
        cluster = create(:cluster)
        ingress_app = build(:clusters_applications_ingress, :updating, cluster: cluster)

        expect(ingress_app.update_in_progress?).to be true
      end
    end
  end

  describe '#update_errored?' do
    context 'when app errored' do
      it 'returns true' do
        cluster = create(:cluster)
        ingress_app = build(:clusters_applications_ingress, :update_errored, cluster: cluster)

        expect(ingress_app.update_errored?).to be true
      end
    end
  end

  describe '#files' do
    let(:application) { ingress }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'should include ingress valid keys in values' do
      expect(values).to include('image')
      expect(values).to include('repository')
      expect(values).to include('stats')
      expect(values).to include('podAnnotations')
    end
  end

  describe '#files_with_replaced_values' do
    let(:application) { build(:clusters_applications_ingress) }
    let(:files) { application.files }

    subject { application.files_with_replaced_values({ hello: :world }) }

    it 'does not modify #files' do
      expect(subject[:'values.yaml']).not_to eq(files)
      expect(files[:'values.yaml']).to eq(application.values)
    end

    it 'returns values.yaml with replaced values' do
      expect(subject[:'values.yaml']).to eq({ hello: :world })
    end

    it 'should include cert files' do
      expect(subject[:'ca.pem']).to be_present
      expect(subject[:'ca.pem']).to eq(application.cluster.application_helm.ca_cert)

      expect(subject[:'cert.pem']).to be_present
      expect(subject[:'key.pem']).to be_present

      cert = OpenSSL::X509::Certificate.new(subject[:'cert.pem'])
      expect(cert.not_after).to be < 60.minutes.from_now
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
  end
end
