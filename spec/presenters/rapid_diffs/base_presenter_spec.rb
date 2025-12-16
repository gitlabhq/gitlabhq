# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::BasePresenter, feature_category: :source_code_management do
  let(:diff_view) { :inline }
  let(:diff_options) { {} }
  let(:environment) { nil }

  subject(:presenter) { described_class.new(Class.new, diff_view, diff_options, nil, environment) }

  describe '#environment' do
    subject(:method) { presenter.environment }

    it { is_expected.to be_nil }

    context 'when environment is provided' do
      let(:environment) { build(:environment) }

      it { is_expected.to eq(environment) }
    end
  end

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
