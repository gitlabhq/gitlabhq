# frozen_string_literal: true

require "spec_helper"

RSpec.describe Wiki do
  describe '.new' do
    it 'verifies that the user is a User' do
      expect { described_class.new(double, 1) }.to raise_error(ArgumentError)
      expect { described_class.new(double, build(:group)) }.to raise_error(ArgumentError)
      expect { described_class.new(double, build(:user)) }.not_to raise_error
      expect { described_class.new(double, nil) }.not_to raise_error
    end
  end
end
