# frozen_string_literal: true
require 'spec_helper'

describe Ci::BuildEnvironmentDeployment, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:build) }
    it { is_expected.to belong_to(:environment) }
    it { is_expected.to belong_to(:deployment) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:build) }
    it { is_expected.to validate_presence_of(:environment) }
  end
end
