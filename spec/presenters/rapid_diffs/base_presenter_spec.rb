# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::BasePresenter, feature_category: :source_code_management do
  subject(:presenter) { described_class.new(Class.new, :inline, {}) }

  describe 'abstract methods' do
    it 'raises a NotImplementedError for #diffs_stats_endpoint' do
      expect { presenter.diffs_stats_endpoint }.to raise_error(NotImplementedError)
    end

    it 'raises a NotImplementedError for #diff_files_endpoint' do
      expect { presenter.diff_files_endpoint }.to raise_error(NotImplementedError)
    end

    it 'raises a NotImplementedError for #diff_file_endpoint' do
      expect { presenter.diff_file_endpoint }.to raise_error(NotImplementedError)
    end

    it 'raises a NotImplementedError for #reload_stream_url' do
      expect { presenter.send(:reload_stream_url) }.to raise_error(NotImplementedError)
    end
  end
end
