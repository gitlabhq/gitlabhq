# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::RemoteObjectStorage, feature_category: :geo_replication do
  # Create an anonymous class that inherits from RemoteObjectStorage but doesn't implement
  # the required interface methods
  let(:dummy_cleaner_class) do
    Class.new(described_class) do
      # Expose private methods for testing
      def public_query_for_row_tracking_the_file(file_path)
        query_for_row_tracking_the_file(file_path)
      end

      def public_expected_file_path_format_regexp
        expected_file_path_format_regexp
      end
    end
  end

  let(:dummy_cleaner) { dummy_cleaner_class.new(:artifacts, nil) }

  describe '#query_for_row_tracking_the_file' do
    it 'raises NotImplementedError if not overridden' do
      expect do
        dummy_cleaner.public_query_for_row_tracking_the_file('path')
      end.to raise_error(NotImplementedError)
    end
  end

  describe '#expected_file_path_format_regexp' do
    it 'raises NotImplementedError if not overridden' do
      expect do
        dummy_cleaner.public_expected_file_path_format_regexp
      end.to raise_error(NotImplementedError)
    end
  end
end
