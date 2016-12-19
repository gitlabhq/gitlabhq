require 'spec_helper'

describe ProjectMetrics, models: true do
  it { is_expected.to belong_to(:project) }

  it { is_expected.to validate_presence_of(:project) }
end
