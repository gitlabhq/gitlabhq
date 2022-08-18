# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::Candidate do
  describe 'associations' do
    it { is_expected.to belong_to(:experiment) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:params) }
    it { is_expected.to have_many(:metrics) }
  end
end
