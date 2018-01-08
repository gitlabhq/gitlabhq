require 'rails_helper'

describe Clusters::Applications::Ingress do
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to validate_presence_of(:cluster) }

  include_examples 'cluster application specs', described_class
end
