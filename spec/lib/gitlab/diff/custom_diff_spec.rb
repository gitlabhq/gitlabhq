# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::CustomDiff do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:ipynb_blob) { repository.blob_at('f6b7a707', 'files/ipython/markdown-table.ipynb') }
  let(:blob) { repository.blob_at('HEAD', 'files/ruby/regex.rb') }

  describe '#preprocess_before_diff' do
    context 'for ipynb files' do
      it 'transforms the diff' do
        expect(described_class.preprocess_before_diff(ipynb_blob.path, nil, ipynb_blob)).not_to include('cells')
      end

      it 'adds the blob to the list of transformed blobs' do
        described_class.preprocess_before_diff(ipynb_blob.path, nil, ipynb_blob)

        expect(described_class.transformed_for_diff?(ipynb_blob)).to be_truthy
      end
    end

    context 'for other files' do
      it 'returns nil' do
        expect(described_class.preprocess_before_diff(blob.path, nil, blob)).to be_nil
      end

      it 'does not add the blob to the list of transformed blobs' do
        described_class.preprocess_before_diff(blob.path, nil, blob)

        expect(described_class.transformed_for_diff?(blob)).to be_falsey
      end
    end

    context 'timeout' do
      subject { described_class.preprocess_before_diff(ipynb_blob.path, nil, ipynb_blob) }

      it 'falls back to nil on timeout' do
        allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
        expect(Timeout).to receive(:timeout).and_raise(Timeout::Error)

        expect(subject).to be_nil
      end

      context 'when in foreground' do
        it 'utilizes timeout for web' do
          expect(Timeout).to receive(:timeout).with(described_class::RENDERED_TIMEOUT_FOREGROUND).and_call_original

          expect(subject).not_to include('cells')
        end

        it 'increments metrics' do
          counter = Gitlab::Metrics.counter(:ipynb_semantic_diff_timeouts_total, 'desc')

          expect(Timeout).to receive(:timeout).and_raise(Timeout::Error)
          expect { subject }.to change { counter.get(source: described_class::FOREGROUND_EXECUTION) }.by(1)
        end
      end

      context 'when in background' do
        before do
          allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
        end

        it 'utilizes longer timeout for sidekiq' do
          expect(Timeout).to receive(:timeout).with(described_class::RENDERED_TIMEOUT_BACKGROUND).and_call_original

          expect(subject).not_to include('cells')
        end

        it 'increments metrics' do
          counter = Gitlab::Metrics.counter(:ipynb_semantic_diff_timeouts_total, 'desc')

          expect(Timeout).to receive(:timeout).and_raise(Timeout::Error)
          expect { subject }.to change { counter.get(source: described_class::BACKGROUND_EXECUTION) }.by(1)
        end
      end
    end

    context 'when invalid ipynb' do
      it 'returns nil' do
        expect(ipynb_blob).to receive(:data).and_return('invalid ipynb')

        expect(described_class.preprocess_before_diff(ipynb_blob.path, nil, ipynb_blob)).to be_nil
      end
    end
  end

  describe '#transformed_blob_data' do
    it 'transforms blob data if file was processed' do
      described_class.preprocess_before_diff(ipynb_blob.path, nil, ipynb_blob)

      expect(described_class.transformed_blob_data(ipynb_blob)).not_to include('cells')
    end

    it 'does not transform blob data if file was not processed' do
      expect(described_class.transformed_blob_data(ipynb_blob)).to be_nil
    end
  end

  describe '#transformed_blob_language' do
    it 'is md when file was preprocessed' do
      described_class.preprocess_before_diff(ipynb_blob.path, nil, ipynb_blob)

      expect(described_class.transformed_blob_language(ipynb_blob)).to eq('md')
    end

    it 'is nil for a .ipynb blob that was not preprocessed' do
      expect(described_class.transformed_blob_language(ipynb_blob)).to be_nil
    end
  end
end
