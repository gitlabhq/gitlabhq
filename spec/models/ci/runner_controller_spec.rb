# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerController, feature_category: :continuous_integration do
  describe 'validations' do
    subject { build(:ci_runner_controller) }

    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
  end
end
