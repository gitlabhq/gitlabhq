# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::CandidateParam do
  describe 'associations' do
    it { is_expected.to belong_to(:candidate) }
  end
end
