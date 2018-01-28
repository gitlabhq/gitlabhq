require 'spec_helper'

describe Clusters::Project do
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to belong_to(:project) }
end
