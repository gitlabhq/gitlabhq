require 'spec_helper'

describe Gitlab::Kubernetes::Helm::InitCommand do
  let(:application) { create(:clusters_applications_helm) }
  let(:commands) do
    <<~EOS
    echo "$CA_CERT" > ca.cert.pem
    echo "$TILLER_CERT" > tiller.cert.pem
    echo "$TILLER_KEY" > tiller.key.pem
    helm init --tiller-tls --tiller-tls-cert ./tiller.cert.pem --tiller-tls-key ./tiller.key.pem --tiller-tls-verify --tls-ca-cert ca.cert.pem >/dev/null
    EOS
  end

  subject { described_class.new(application.name) }

  it_behaves_like 'helm commands'
end
