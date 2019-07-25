# frozen_string_literal: true

shared_examples 'cluster application helm specs' do |application_name|
  let(:application) { create(application_name) }

  describe '#uninstall_command' do
    subject { application.uninstall_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::DeleteCommand) }

    it 'has the application name' do
      expect(subject.name).to eq(application.name)
    end

    it 'has files' do
      expect(subject.files).to eq(application.files)
    end

    it 'is rbac' do
      expect(subject).to be_rbac
    end

    context 'on a non rbac enabled cluster' do
      before do
        application.cluster.platform_kubernetes.abac!
      end

      it { is_expected.not_to be_rbac }
    end
  end

  describe '#files' do
    subject { application.files }

    context 'when the helm application does not have a ca_cert' do
      before do
        application.cluster.application_helm.ca_cert = nil
      end

      it 'does not include cert files when there is no ca_cert entry' do
        expect(subject).not_to include(:'ca.pem', :'cert.pem', :'key.pem')
      end
    end

    it 'includes cert files when there is a ca_cert entry' do
      expect(subject).to include(:'ca.pem', :'cert.pem', :'key.pem')
      expect(subject[:'ca.pem']).to eq(application.cluster.application_helm.ca_cert)

      cert = OpenSSL::X509::Certificate.new(subject[:'cert.pem'])
      expect(cert.not_after).to be < 60.minutes.from_now
    end
  end
end
