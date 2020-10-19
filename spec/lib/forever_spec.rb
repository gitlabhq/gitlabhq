# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Forever do
  describe '.date' do
    subject { described_class.date }

    it 'returns Postgresql future date' do
      travel_to(Date.new(2999, 12, 31)) do
        is_expected.to be > Date.today
      end
    end
  end
end
