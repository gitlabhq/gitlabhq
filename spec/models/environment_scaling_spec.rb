require 'spec_helper'

describe EnvironmentScaling do
  it { is_expected.to belong_to(:environment) }
end
