# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::Helm::Pod do
  describe '#generate' do
    using RSpec::Parameterized::TableSyntax

    where(:helm_major_version, :expected_helm_version, :expected_command_env) do
      2 | '2.17.0' | [:TILLER_NAMESPACE]
      3 | '3.2.4'  | nil
    end

    with_them do
      let(:cluster) { create(:cluster, helm_major_version: helm_major_version) }
      let(:app) { create(:clusters_applications_prometheus, cluster: cluster) }
      let(:command) { app.install_command }
      let(:namespace) { Gitlab::Kubernetes::Helm::NAMESPACE }
      let(:service_account_name) { nil }

      subject { described_class.new(command, namespace, service_account_name: service_account_name) }

      context 'with a command' do
        it 'generates a Kubeclient::Resource' do
          expect(subject.generate).to be_a_kind_of(Kubeclient::Resource)
        end

        it 'generates the appropriate metadata' do
          metadata = subject.generate.metadata
          expect(metadata.name).to eq("install-#{app.name}")
          expect(metadata.namespace).to eq('gitlab-managed-apps')
          expect(metadata.labels['gitlab.org/action']).to eq('install')
          expect(metadata.labels['gitlab.org/application']).to eq(app.name)
        end

        it 'generates a container spec' do
          spec = subject.generate.spec
          expect(spec.containers.count).to eq(1)
        end

        it 'generates the appropriate specifications for the container' do
          container = subject.generate.spec.containers.first
          expect(container.name).to eq('helm')
          expect(container.image).to eq("registry.gitlab.com/gitlab-org/cluster-integration/helm-install-image/releases/#{expected_helm_version}-kube-1.13.12-alpine-3.12")
          expect(container.env.map(&:name)).to include(:HELM_VERSION, :COMMAND_SCRIPT, *expected_command_env)
          expect(container.command).to match_array(["/bin/sh"])
          expect(container.args).to match_array(["-c", "$(COMMAND_SCRIPT)"])
        end

        it 'includes a never restart policy' do
          spec = subject.generate.spec
          expect(spec.restartPolicy).to eq('Never')
        end

        it 'includes volumes for the container' do
          container = subject.generate.spec.containers.first
          expect(container.volumeMounts.first['name']).to eq('configuration-volume')
          expect(container.volumeMounts.first['mountPath']).to eq("/data/helm/#{app.name}/config")
        end

        it 'includes a volume inside the specification' do
          spec = subject.generate.spec
          expect(spec.volumes.first['name']).to eq('configuration-volume')
        end

        it 'mounts configMap specification in the volume' do
          volume = subject.generate.spec.volumes.first
          expect(volume.configMap['name']).to eq("values-content-configuration-#{app.name}")
          expect(volume.configMap['items'].first['key']).to eq(:'values.yaml')
          expect(volume.configMap['items'].first['path']).to eq(:'values.yaml')
        end

        it 'has no serviceAccountName' do
          spec = subject.generate.spec
          expect(spec.serviceAccountName).to be_nil
        end

        context 'with a service_account_name' do
          let(:service_account_name) { 'sa' }

          it 'uses the serviceAccountName provided' do
            spec = subject.generate.spec
            expect(spec.serviceAccountName).to eq(service_account_name)
          end
        end
      end
    end
  end
end
