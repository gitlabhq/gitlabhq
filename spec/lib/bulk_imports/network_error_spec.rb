# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::NetworkError, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let(:tracker) { double(id: 1, stage: 2, entity: double(id: 3)) }

  describe '.new' do
    it 'requires either a message or a HTTP response' do
      expect { described_class.new }
        .to raise_error(ArgumentError, 'message or response required')
    end
  end

  describe '#retriable?' do
    it 'returns true for MAX_RETRIABLE_COUNT times when cause if one of RETRIABLE_EXCEPTIONS' do
      raise described_class::RETRIABLE_EXCEPTIONS.sample
    rescue StandardError => cause
      begin
        raise described_class, cause
      rescue StandardError => exception
        described_class::MAX_RETRIABLE_COUNT.times do
          expect(exception.retriable?(tracker)).to eq(true)
        end

        expect(exception.retriable?(tracker)).to eq(false)
      end
    end

    it 'returns true for MAX_RETRIABLE_COUNT times when response is one of RETRIABLE_CODES' do
      exception = described_class.new(response: double(code: 429))

      described_class::MAX_RETRIABLE_COUNT.times do
        expect(exception.retriable?(tracker)).to eq(true)
      end

      expect(exception.retriable?(tracker)).to eq(false)
    end

    it 'returns false for other exceptions' do
      raise StandardError
    rescue StandardError => cause
      begin
        raise described_class, cause
      rescue StandardError => exception
        expect(exception.retriable?(tracker)).to eq(false)
      end
    end

    context 'when entity is passed' do
      it 'increments entity cache key' do
        entity = create(:bulk_import_entity)
        exception = described_class.new('Error!')

        allow(exception).to receive(:cause).and_return(SocketError.new('Error!'))

        expect(Gitlab::Cache::Import::Caching)
          .to receive(:increment)
          .with("bulk_imports/#{entity.id}/network_error/SocketError")
          .and_call_original

        exception.retriable?(entity)
      end
    end
  end

  describe '#retry_delay' do
    context 'when the exception is not a rate limit error' do
      let(:exception) { described_class.new('Error!') }

      it 'returns the default value' do
        expect(exception.retry_delay).to eq(described_class::DEFAULT_RETRY_DELAY_SECONDS.seconds)
      end

      context 'when the exception is a decompression error' do
        before do
          allow(exception).to receive(:cause).and_return(Zlib::Error.new('Error!'))
        end

        it 'returns the exception delay value' do
          expect(exception.retry_delay).to eq(60.seconds)
        end
      end

      context 'when the exception is a no space left error' do
        before do
          allow(exception).to receive(:cause).and_return(Errno::ENOSPC.new('Error!'))
        end

        it 'returns the exception delay value' do
          expect(exception.retry_delay).to eq(120.seconds)
        end
      end
    end

    context 'when the exception is a rate limit error' do
      it 'returns the "Retry-After"' do
        exception = described_class.new(response: double(code: 429, headers: { 'Retry-After' => 20 }))

        expect(exception.retry_delay).to eq(20.seconds)
      end

      it 'returns the default value when there is no "Retry-After" header' do
        exception = described_class.new(response: double(code: 429, headers: {}))

        expect(exception.retry_delay).to eq(described_class::DEFAULT_RETRY_DELAY_SECONDS.seconds)
      end
    end
  end
end
