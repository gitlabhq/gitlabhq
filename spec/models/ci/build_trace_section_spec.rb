require 'spec_helper'

describe Ci::BuildTraceSection, model: true do
  it { is_expected.to belong_to(:build)}
  it { is_expected.to belong_to(:project)}
  it { is_expected.to belong_to(:section_name)}

  it { is_expected.to validate_presence_of(:section_name) }
  it { is_expected.to validate_presence_of(:build) }
  it { is_expected.to validate_presence_of(:project) }
end
