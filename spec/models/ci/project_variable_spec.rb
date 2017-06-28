require 'spec_helper'

describe Ci::ProjectVariable, models: true do
  subject { build(:ci_project_variable) }

  it { is_expected.to validate_uniqueness_of(:key).scoped_to(:project_id) }
end
