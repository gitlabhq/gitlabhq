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
end

RSpec.shared_examples 'rapid diffs presenter diffs methods' do |sorted:|
  describe '#diff_files' do
    let(:diffs) { instance_double(Gitlab::Diff::FileCollection::Base) }
    let(:diff_files) { [instance_double(Gitlab::Diff::File)] }

    before do
      allow(presenter).to receive(:diffs_resource).and_return(diffs)
      allow(diffs).to receive(:diff_files).and_return(diff_files)
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
    let(:diff_files) { [instance_double(Gitlab::Diff::File)] }

    before do
      allow(resource).to receive(:diffs_for_streaming).and_return(streaming_diffs)
      allow(streaming_diffs).to receive(:diff_files).and_return(diff_files)
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
    it 'calls diffs_for_streaming_by_changed_paths on the resource' do
      block = proc {}
      expect(resource).to receive(:diffs_for_streaming_by_changed_paths).with({}, &block)

      presenter.diff_files_for_streaming_by_changed_paths({}, &block)
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
