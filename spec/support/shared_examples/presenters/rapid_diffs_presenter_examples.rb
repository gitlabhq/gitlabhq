# frozen_string_literal: true

RSpec.shared_examples 'rapid diffs presenter base diffs_resource' do
  describe '#diffs_resource' do
    let(:diffs) { instance_double(Gitlab::Diff::FileCollection::Base) }

    it 'calls diffs on the resource with merged options' do
      expect(resource).to receive(:diffs).with(diff_options).and_return(diffs)

      expect(presenter.diffs_resource).to eq(diffs)
    end

    context 'when additional options are provided' do
      let(:extra_options) { { paths: ['file.rb'] } }

      it 'merges the options with diff_options' do
        expect(resource).to receive(:diffs).with(diff_options.merge(extra_options)).and_return(diffs)

        presenter.diffs_resource(extra_options)
      end
    end
  end

  describe '#linked_file' do
    context 'when linked file is not found' do
      let(:request_params) { { file_path: 'nonexistent.txt' } }
      let(:diff_files) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: []) }

      before do
        allow(resource).to receive(:diffs).and_return(diff_files)
      end

      it 'returns nil' do
        expect(presenter.linked_file).to be_nil
      end
    end
  end
end

RSpec.shared_examples 'rapid diffs presenter diffs methods' do |sorted:|
  describe '#diff_files' do
    let(:diffs) { instance_double(Gitlab::Diff::FileCollection::Base) }
    let(:diff_files) { instance_double(Gitlab::Git::DiffCollection) }

    before do
      allow(presenter).to receive(:diffs_resource).and_return(diffs)
      allow(diffs).to receive(:diff_files).and_return(diff_files)
      allow(diff_files).to receive(:decorate!).and_return(diff_files)
    end

    it 'returns diff files from diffs_resource' do
      expect(diffs).to receive(:diff_files).with(sorted: sorted)

      presenter.diff_files
    end

    context 'when additional options are provided' do
      let(:extra_options) { { expanded: true } }

      it 'passes options to diffs_resource' do
        expect(presenter).to receive(:diffs_resource).with(extra_options).and_return(diffs)

        presenter.diff_files(extra_options)
      end
    end
  end

  describe '#diff_files_for_streaming' do
    let(:streaming_diffs) { instance_double(Gitlab::Diff::FileCollection::Base) }
    let(:diff_files) { instance_double(Gitlab::Git::DiffCollection) }

    before do
      allow(resource).to receive(:diffs_for_streaming).and_return(streaming_diffs)
      allow(streaming_diffs).to receive(:diff_files).and_return(diff_files)
      allow(diff_files).to receive(:decorate!).and_return(diff_files)
    end

    it 'returns diff files for streaming' do
      expect(streaming_diffs).to receive(:diff_files).with(sorted: sorted)

      presenter.diff_files_for_streaming
    end

    context 'when options are provided' do
      let(:options) { { offset_index: 10 } }

      it 'passes options to diffs_for_streaming' do
        expect(resource).to receive(:diffs_for_streaming).with(options).and_return(streaming_diffs)

        presenter.diff_files_for_streaming(options)
      end
    end
  end

  describe '#diff_files_for_streaming_by_changed_paths' do
    it 'calls diffs_for_streaming_by_changed_paths on the resource and yields transformed files' do
      diff_file = build(:diff_file)
      yielded_files = nil

      allow(resource).to receive(:diffs_for_streaming_by_changed_paths).and_yield([diff_file])

      presenter.diff_files_for_streaming_by_changed_paths({}) do |files|
        yielded_files = files
      end

      expect(yielded_files).to eq([diff_file])
    end

    context 'when no block is given' do
      it 'does not yield' do
        allow(resource).to receive(:diffs_for_streaming_by_changed_paths).and_yield([])

        expect { presenter.diff_files_for_streaming_by_changed_paths({}) }.not_to raise_error
      end
    end

    context 'when options are provided' do
      let(:options) { { offset_index: 10 } }

      it 'passes options to diffs_for_streaming_by_changed_paths' do
        block = proc {}
        expect(resource).to receive(:diffs_for_streaming_by_changed_paths).with(options, &block)

        presenter.diff_files_for_streaming_by_changed_paths(options, &block)
      end
    end
  end
end
