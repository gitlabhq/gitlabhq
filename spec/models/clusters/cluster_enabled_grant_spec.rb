# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::ClusterEnabledGrant do
  it { is_expected.to belong_to :namespace }
end
