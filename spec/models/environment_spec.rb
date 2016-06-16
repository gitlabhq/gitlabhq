require 'spec_helper'

describe Environment, models: true do
  let(:environment) { create(:environment) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:deployments) }

  it { is_expected.to delegate_method(:last_deployment).to(:deployments).as(:last) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
  it { is_expected.to validate_length_of(:name).is_within(0..255) }
end
