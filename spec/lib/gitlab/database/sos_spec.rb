# frozen_string_literal: true

require 'spec_helper'

# WIP
RSpec.describe Gitlab::Database::Sos, feature_category: :database do
  describe '#run' do
    let(:temp_directory) { Dir.mktmpdir }
    let(:output_file_path) { temp_directory }

    after do
      FileUtils.remove_entry(temp_directory)
    end

    it "executes sos" do
      result = described_class.run(output_file_path)
      expect(result).to eq(Gitlab::Database::Sos::TASKS)
    end
  end
end
