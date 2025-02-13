# frozen_string_literal: true

require 'spec_helper'

# WIP
RSpec.describe Gitlab::Database::Sos, feature_category: :database do
  describe '#run' do
    let(:temp_directory) { Dir.mktmpdir }
    let(:output_file_path) { temp_directory }
    let(:task) { Gitlab::Database::Sos::DbStatsActivity }

    after do
      FileUtils.remove_entry(temp_directory)
    end

    it "creates temp directory of pg data" do
      stub_const("#{described_class}::TASKS", [task])
      result = described_class.run(output_file_path)
      expect(result.size).to be >= 1
      expect(Dir.glob(File.join(temp_directory, '**', '*.csv'))).not_to be_empty
    end
  end
end
