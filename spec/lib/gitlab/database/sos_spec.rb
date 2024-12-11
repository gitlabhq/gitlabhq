# frozen_string_literal: true

require 'spec_helper'

# WIP
RSpec.describe Gitlab::Database::Sos, feature_category: :database do
  describe '#run' do
    it "executes sos" do
      result = described_class.run
      expect(result).to eq(Gitlab::Database::Sos::TASKS)
    end
  end
end
