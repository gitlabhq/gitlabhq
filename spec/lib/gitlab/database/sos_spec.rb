# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Sos, feature_category: :database do
  describe '#run' do
    let(:temp_directory) { Dir.mktmpdir }
    let(:output_file_path) { temp_directory }
    let(:connection) { ApplicationRecord.connection }
    let(:db_name) { 'test_db' }

    before do
      stub_const("#{described_class}::DURATION", 3.seconds)
      stub_const("#{described_class}::TIME", 0)
      allow(Gitlab::Database::EachDatabase).to receive(:each_connection).and_yield(connection, db_name)
    end

    after do
      FileUtils.remove_entry(temp_directory)
    end

    it "creates a temp directory of pg data" do
      described_class.run(output_file_path)
      expect(Dir.glob(File.join(output_file_path, '**', '*.csv'))).not_to be_empty
    end
  end
end
