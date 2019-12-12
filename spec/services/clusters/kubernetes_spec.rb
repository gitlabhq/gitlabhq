# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Kubernetes do
  it { is_expected.to be_const_defined(:GITLAB_SERVICE_ACCOUNT_NAME) }
  it { is_expected.to be_const_defined(:GITLAB_SERVICE_ACCOUNT_NAMESPACE) }
  it { is_expected.to be_const_defined(:GITLAB_ADMIN_TOKEN_NAME) }
  it { is_expected.to be_const_defined(:GITLAB_CLUSTER_ROLE_BINDING_NAME) }
  it { is_expected.to be_const_defined(:GITLAB_CLUSTER_ROLE_NAME) }
  it { is_expected.to be_const_defined(:PROJECT_CLUSTER_ROLE_NAME) }
  it { is_expected.to be_const_defined(:GITLAB_KNATIVE_SERVING_ROLE_NAME) }
  it { is_expected.to be_const_defined(:GITLAB_KNATIVE_SERVING_ROLE_BINDING_NAME) }
  it { is_expected.to be_const_defined(:GITLAB_CROSSPLANE_DATABASE_ROLE_NAME) }
  it { is_expected.to be_const_defined(:GITLAB_CROSSPLANE_DATABASE_ROLE_BINDING_NAME) }
  it { is_expected.to be_const_defined(:GITLAB_KNATIVE_VERSION_ROLE_NAME) }
  it { is_expected.to be_const_defined(:GITLAB_KNATIVE_VERSION_ROLE_BINDING_NAME) }
  it { is_expected.to be_const_defined(:KNATIVE_SERVING_NAMESPACE) }
end
