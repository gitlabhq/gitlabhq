require 'spec_helper'

describe ProjectAutoDevops, type: :model do
  subject { build_stubbed(:project_auto_devops) }

  it { is_expected.to belong_to(:project) }

  it { is_expected.to respond_to(:created_at) }
  it { is_expected.to respond_to(:updated_at) }

  it { is_expected.to be_enabled }
end
