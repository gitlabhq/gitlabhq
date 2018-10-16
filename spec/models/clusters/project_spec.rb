require 'spec_helper'

describe Clusters::Project do
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:kubernetes_namespaces) }
  it { is_expected.to have_one(:last_kubernetes_namespace) }

  it { is_expected.to respond_to(:kubernetes_namespace) }
end
