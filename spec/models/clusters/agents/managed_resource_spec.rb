# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::ManagedResource, feature_category: :deployment_management do
  it { is_expected.to belong_to(:build).class_name('Ci::Build') }
  it { is_expected.to belong_to(:cluster_agent).class_name('Clusters::Agent') }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:environment) }

  it { is_expected.to validate_length_of(:template_name).is_at_most(1024) }
end
