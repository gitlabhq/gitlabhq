# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerControllerToken, feature_category: :continuous_integration do
  it { is_expected.to belong_to(:runner_controller).class_name('Ci::RunnerController') }

  describe 'validations' do
    subject { build(:ci_runner_controller_token) }

    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
    it { is_expected.to validate_presence_of(:token_digest) }
    it { is_expected.to validate_length_of(:token_digest).is_at_most(255) }
    it { is_expected.to validate_uniqueness_of(:token_digest) }
  end
end
