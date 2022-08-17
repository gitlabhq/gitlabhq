# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::Experiment do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:candidates) }
  end
end
