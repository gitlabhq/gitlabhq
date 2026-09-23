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

  describe '#diff_collection' do
    let(:file_one) { build(:diff_file) }
    let(:file_two) { build(:diff_file) }
    let(:linked_file) { nil }
    let(:current_user) { nil }

    subject(:presenter) do
      described_class.new(Class.new, diff_view: diff_view, diff_options: diff_options,
        current_user: current_user, request_params: nil, environment: environment)
    end

    before do
      allow(presenter).to receive_messages(linked_file: linked_file, diffs_slice: [file_one, file_two])
    end

    context 'when a linked file is present' do
      let(:linked_file) { file_one }

      it 'returns only the linked file, ignoring the slice' do
        expect(presenter.diff_collection).to eq([linked_file])
      end
    end

    context 'when the diffs slice is nil' do
      before do
        allow(presenter).to receive(:diffs_slice).and_return(nil)
      end

      it 'returns an empty collection' do
        expect(presenter.diff_collection).to eq([])
      end
    end

    context 'when not in file-by-file mode' do
      it 'returns the full slice' do
        expect(presenter.diff_collection).to match_array([file_one, file_two])
      end
    end

    context 'when in file-by-file mode' do
      let(:current_user) { build_stubbed(:user, view_diffs_file_by_file: true) }

      it 'returns the slice, which the offset has already capped to one file' do
        allow(presenter).to receive(:diffs_slice).and_return([file_one])

        expect(presenter.diff_collection).to eq([file_one])
      end

      context 'when no file was rendered' do
        before do
          allow(presenter).to receive(:diffs_slice).and_return(nil)
        end

        it 'returns an empty collection' do
          expect(presenter.diff_collection).to eq([])
        end
      end
    end
  end

  describe '#offset' do
    let(:current_user) { nil }

    subject(:presenter) do
      described_class.new(Class.new, diff_view: diff_view, diff_options: diff_options,
        current_user: current_user, request_params: nil, environment: environment)
    end

    before do
      allow(presenter).to receive(:linked_file).and_return(nil)
    end

    context 'when a linked file is present' do
      it 'is one' do
        allow(presenter).to receive(:linked_file).and_return(build(:diff_file))

        expect(presenter.offset).to eq(1)
      end
    end

    context 'when the page is lazy' do
      it 'is nil' do
        presenter.baseline_offset = nil

        expect(presenter.offset).to be_nil
      end
    end

    context 'when not in file-by-file mode' do
      it 'is the baseline offset' do
        presenter.baseline_offset = 5

        expect(presenter.offset).to eq(5)
      end
    end

    context 'when in file-by-file mode' do
      let(:current_user) { build_stubbed(:user, view_diffs_file_by_file: true) }

      it 'is one, so only the file that renders is fetched' do
        presenter.baseline_offset = 5

        expect(presenter.offset).to eq(1)
      end
    end
  end

  describe '#initial_file' do
    let(:file_one) { build(:diff_file) }

    subject(:presenter) do
      described_class.new(Class.new, diff_view: diff_view, diff_options: diff_options,
        current_user: current_user, request_params: nil, environment: environment)
    end

    context 'when not in file-by-file mode' do
      let(:current_user) { nil }

      it 'is nil' do
        expect(presenter.initial_file).to be_nil
      end
    end

    context 'when in file-by-file mode' do
      let(:current_user) { build_stubbed(:user, view_diffs_file_by_file: true) }

      before do
        allow(presenter).to receive_messages(linked_file: nil, diffs_slice: [file_one])
      end

      it 'names the rendered file' do
        expect(presenter.initial_file).to eq({ old_path: file_one.old_path, new_path: file_one.new_path })
      end

      context 'when nothing was rendered' do
        before do
          allow(presenter).to receive(:diffs_slice).and_return([])
        end

        it 'is nil' do
          expect(presenter.initial_file).to be_nil
        end
      end
    end
  end
end
