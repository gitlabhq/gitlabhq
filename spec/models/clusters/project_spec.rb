# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Project do
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:kubernetes_namespaces) }
end
