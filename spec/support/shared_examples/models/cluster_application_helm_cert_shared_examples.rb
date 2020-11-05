# frozen_string_literal: true

RSpec.shared_examples 'cluster application helm specs' do |application_name|
  let(:application) { create(application_name) } # rubocop:disable Rails/SaveBang

  describe '#uninstall_command' do
    subject { application.uninstall_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::V3::DeleteCommand) }

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
