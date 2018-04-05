require 'spec_helper'

describe Gitlab::Kubernetes::Helm::InitCommand do
  let(:application) { create(:clusters_applications_helm) }
  let(:init_command) { described_class.new(application.name) }

  describe '#generate_script' do
    let(:command) do
      <<~MSG.chomp
        set -eo pipefail
        apk add -U ca-certificates openssl >/dev/null
        wget -q -O - https://kubernetes-helm.storage.googleapis.com/helm-v2.7.0-linux-amd64.tar.gz | tar zxC /tmp >/dev/null
        mv /tmp/linux-amd64/helm /usr/bin/
        helm init >/dev/null
      MSG
    end

    subject { init_command.generate_script }

    it 'should return the appropriate command' do
      is_expected.to eq(command)
    end
  end
end
