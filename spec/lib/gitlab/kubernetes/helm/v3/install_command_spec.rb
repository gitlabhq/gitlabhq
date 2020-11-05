# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::Helm::V3::InstallCommand do
  subject(:install_command) do
    described_class.new(
      name: 'app-name',
      chart: 'chart-name',
      rbac: rbac,
      files: files,
      version: version,
      repository: repository,
      preinstall: preinstall,
      postinstall: postinstall
    )
  end

  let(:files) { { 'ca.pem': 'some file content' } }
  let(:repository) { 'https://repository.example.com' }
  let(:rbac) { false }
  let(:version) { '1.2.3' }
  let(:preinstall) { nil }
  let(:postinstall) { nil }

  it_behaves_like 'helm command generator' do
    let(:commands) do
      <<~EOS
      helm repo add app-name https://repository.example.com
      helm repo update
      #{helm_install_comand}
      EOS
    end

    let(:helm_install_comand) do
      <<~EOS.squish
      helm upgrade app-name chart-name
        --install
        --atomic
        --cleanup-on-fail
        --reset-values
        --version 1.2.3
        --set rbac.create\\=false,rbac.enabled\\=false
        --namespace gitlab-managed-apps
        -f /data/helm/app-name/config/values.yaml
      EOS
    end
  end

  context 'when rbac is true' do
    let(:rbac) { true }

    it_behaves_like 'helm command generator' do
      let(:commands) do
        <<~EOS
        helm repo add app-name https://repository.example.com
        helm repo update
        #{helm_install_command}
        EOS
      end

      let(:helm_install_command) do
        <<~EOS.squish
        helm upgrade app-name chart-name
          --install
          --atomic
          --cleanup-on-fail
          --reset-values
          --version 1.2.3
          --set rbac.create\\=true,rbac.enabled\\=true
          --namespace gitlab-managed-apps
          -f /data/helm/app-name/config/values.yaml
        EOS
      end
    end
  end

  context 'when there is a pre-install script' do
    let(:preinstall) { ['/bin/date', '/bin/true'] }

    it_behaves_like 'helm command generator' do
      let(:commands) do
        <<~EOS
        helm repo add app-name https://repository.example.com
        helm repo update
        /bin/date
        /bin/true
        #{helm_install_command}
        EOS
      end

      let(:helm_install_command) do
        <<~EOS.squish
        helm upgrade app-name chart-name
          --install
          --atomic
          --cleanup-on-fail
          --reset-values
          --version 1.2.3
          --set rbac.create\\=false,rbac.enabled\\=false
          --namespace gitlab-managed-apps
          -f /data/helm/app-name/config/values.yaml
        EOS
      end
    end
  end

  context 'when there is a post-install script' do
    let(:postinstall) { ['/bin/date', "/bin/false\n"] }

    it_behaves_like 'helm command generator' do
      let(:commands) do
        <<~EOS
        helm repo add app-name https://repository.example.com
        helm repo update
        #{helm_install_command}
        /bin/date
        /bin/false
        EOS
      end

      let(:helm_install_command) do
        <<~EOS.squish
        helm upgrade app-name chart-name
          --install
          --atomic
          --cleanup-on-fail
          --reset-values
          --version 1.2.3
          --set rbac.create\\=false,rbac.enabled\\=false
          --namespace gitlab-managed-apps
          -f /data/helm/app-name/config/values.yaml
        EOS
      end
    end
  end

  context 'when there is no version' do
    let(:version) { nil }

    it_behaves_like 'helm command generator' do
      let(:commands) do
        <<~EOS
        helm repo add app-name https://repository.example.com
        helm repo update
        #{helm_install_command}
        EOS
      end

      let(:helm_install_command) do
        <<~EOS.squish
        helm upgrade app-name chart-name
          --install
          --atomic
          --cleanup-on-fail
          --reset-values
          --set rbac.create\\=false,rbac.enabled\\=false
          --namespace gitlab-managed-apps
          -f /data/helm/app-name/config/values.yaml
        EOS
      end
    end
  end

  it_behaves_like 'helm command' do
    let(:command) { install_command }
  end
end
