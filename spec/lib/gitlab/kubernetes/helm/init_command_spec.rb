require 'spec_helper'

describe Gitlab::Kubernetes::Helm::InitCommand do
  let(:application) { create(:clusters_applications_helm) }
  let(:commands) { 'helm init >/dev/null' }

  subject { described_class.new(application.name) }

  it_behaves_like 'helm commands'
end
