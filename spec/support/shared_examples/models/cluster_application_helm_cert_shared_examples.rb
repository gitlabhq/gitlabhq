# frozen_string_literal: true

RSpec.shared_examples 'cluster application helm specs' do |application_name|
  let(:application) { create(application_name) }

  describe '#uninstall_command' do
    subject { application.uninstall_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::DeleteCommand) }

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

    context 'managed_apps_local_tiller feature flag is disabled' do
      before do
        stub_feature_flags(managed_apps_local_tiller: false)
      end

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

    context 'managed_apps_local_tiller feature flag is enabled' do
      before do
        stub_feature_flags(managed_apps_local_tiller: application.cluster.clusterable)
      end

      it 'does not include cert files' do
        expect(subject).not_to include(:'ca.pem', :'cert.pem', :'key.pem')
      end

      context 'when cluster does not have helm installed' do
        let(:application) { create(application_name, :no_helm_installed) }

        it 'does not include cert files' do
          expect(subject).not_to include(:'ca.pem', :'cert.pem', :'key.pem')
        end
      end
    end
  end
end
