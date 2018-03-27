require 'rails_helper'

describe Gitlab::Kubernetes::Helm::Pod do
  describe '#generate' do
    let(:cluster) { create(:cluster) }
    let(:app) {  create(:clusters_applications_prometheus, cluster: cluster) }
    let(:command) {  app.install_command }
    let(:namespace) { Gitlab::Kubernetes::Helm::NAMESPACE }

    subject { described_class.new(command, namespace) }

    shared_examples 'helm pod' do
      it 'should generate a Kubeclient::Resource' do
        expect(subject.generate).to be_a_kind_of(Kubeclient::Resource)
      end

      it 'should generate the appropriate metadata' do
        metadata = subject.generate.metadata
        expect(metadata.name).to eq("install-#{app.name}")
        expect(metadata.namespace).to eq('gitlab-managed-apps')
        expect(metadata.labels['gitlab.org/action']).to eq('install')
        expect(metadata.labels['gitlab.org/application']).to eq(app.name)
      end

      it 'should generate a container spec' do
        spec = subject.generate.spec
        expect(spec.containers.count).to eq(1)
      end

      it 'should generate the appropriate specifications for the container' do
        container = subject.generate.spec.containers.first
        expect(container.name).to eq('helm')
        expect(container.image).to eq('alpine:3.6')
        expect(container.env.count).to eq(3)
        expect(container.env.map(&:name)).to match_array([:HELM_VERSION, :TILLER_NAMESPACE, :COMMAND_SCRIPT])
        expect(container.command).to match_array(["/bin/sh"])
        expect(container.args).to match_array(["-c", "$(COMMAND_SCRIPT)"])
      end

      it 'should include a never restart policy' do
        spec = subject.generate.spec
        expect(spec.restartPolicy).to eq('Never')
      end
    end

    context 'with a install command' do
      it_behaves_like 'helm pod'

      it 'should include volumes for the container' do
        container = subject.generate.spec.containers.first
        expect(container.volumeMounts.first['name']).to eq('configuration-volume')
        expect(container.volumeMounts.first['mountPath']).to eq("/data/helm/#{app.name}/config")
      end

      it 'should include a volume inside the specification' do
        spec = subject.generate.spec
        expect(spec.volumes.first['name']).to eq('configuration-volume')
      end

      it 'should mount configMap specification in the volume' do
        volume = subject.generate.spec.volumes.first
        expect(volume.configMap['name']).to eq("values-content-configuration-#{app.name}")
        expect(volume.configMap['items'].first['key']).to eq('values')
        expect(volume.configMap['items'].first['path']).to eq('values.yaml')
      end
    end

    context 'with a init command' do
      let(:app) { create(:clusters_applications_helm, cluster: cluster) }

      it_behaves_like 'helm pod'

      it 'should not include volumeMounts inside the container' do
        container = subject.generate.spec.containers.first
        expect(container.volumeMounts).to be_nil
      end

      it 'should not a volume inside the specification' do
        spec = subject.generate.spec
        expect(spec.volumes).to be_nil
      end
    end
  end
end
