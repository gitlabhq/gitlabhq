# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::BasePresenter, feature_category: :source_code_management do
  let(:diff_view) { :inline }
  let(:diff_options) { {} }
  let(:environment) { nil }

  subject(:presenter) do
    described_class.new(Class.new, diff_view: diff_view, diff_options: diff_options, request_params: nil,
      environment: environment)
  end

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

  describe '#transform_file' do
    let(:diff_file) { build(:diff_file) }
    let(:request_params) { { line: 'line_abc_20' } }

    subject(:presenter) do
      described_class.new(Class.new, diff_view: diff_view, diff_options: diff_options,
        request_params: request_params, environment: environment)
    end

    context 'when the file is the linked file' do
      before do
        diff_file.linked = true
      end

      it 'unfolds it through the linked line unfolder built from the line param' do
        unfolder = instance_double(Gitlab::Diff::LinkedLineUnfolder)

        expect(Gitlab::Diff::LinkedLineUnfolder).to receive(:from_param).with('line_abc_20').and_return(unfolder)
        expect(unfolder).to receive(:unfold!).with(diff_file)

        presenter.send(:transform_file, diff_file)
      end
    end

    context 'when the file is not the linked file' do
      it 'does not unfold' do
        expect(diff_file).not_to receive(:unfold_diff_lines)

        expect(presenter.send(:transform_file, diff_file)).to eq(diff_file)
      end
    end

    context 'when there is no line param' do
      let(:request_params) { {} }

      before do
        diff_file.linked = true
      end

      it 'does not unfold' do
        allow(Gitlab::Diff::LinkedLineUnfolder).to receive(:from_param).and_return(nil)
        expect(diff_file).not_to receive(:unfold_diff_lines)

        expect(presenter.send(:transform_file, diff_file)).to eq(diff_file)
      end
    end
  end
end
