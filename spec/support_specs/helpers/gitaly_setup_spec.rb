# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../support/helpers/gitaly_setup'

RSpec.describe GitalySetup, feature_category: :gitaly do
  describe '.runtime_dir' do
    subject(:result) { described_class.runtime_dir }

    context 'when the candidate socket path is within the OS limit' do
      before do
        # Stub expand_path to return a short candidate path that keeps the
        # full socket path (candidate + '/gitaly-99999/sock.d/tsocket') at
        # or below 103 characters.
        allow(described_class).to receive(:expand_path).with('tmp/run').and_return('/tmp/run')
      end

      it 'uses the default tmp/run location' do
        expect(result).to eq('/tmp/run')
      end
    end

    context 'when the candidate socket path would exceed the OS limit' do
      let(:long_base_path) do
        # Construct a path long enough that the full socket path exceeds 103 chars.
        # '/gitaly-99999/sock.d/tsocket' is 28 chars, so the base must be > 75 chars.
        "/tmp/#{'a' * 80}"
      end

      before do
        allow(described_class).to receive(:expand_path).with('tmp/run').and_return(long_base_path)
      end

      it 'falls back to a short /tmp-based path' do
        expect(result).to eq("/tmp/gitaly-test-#{Process.uid}")
      end

      it 'ensures the fallback socket path is within the OS limit' do
        fallback_socket = File.join(result, 'gitaly-99999', 'sock.d', 'tsocket')

        expect(fallback_socket.bytesize).to be <= 103
      end
    end
  end
end
