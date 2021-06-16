# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::SizeLimiter::Compressor do
  using RSpec::Parameterized::TableSyntax

  let(:base_payload) do
    {
      "class" => "ARandomWorker",
      "queue" => "a_worker",
      "retry" => true,
      "jid" => "d774900367dc8b2962b2479c",
      "created_at" => 1234567890,
      "enqueued_at" => 1234567890
    }
  end

  describe '.compressed?' do
    where(:job, :result) do
      {} | false
      base_payload.merge("args" => [123, 'hello', ['world']]) | false
      base_payload.merge("args" => ['eJzLSM3JyQcABiwCFQ=='], 'compressed' => true) | true
    end

    with_them do
      it 'returns whether the job payload is compressed' do
        expect(described_class.compressed?(job)).to eql(result)
      end
    end
  end

  describe '.compress' do
    where(:args) do
      [
        nil,
        [],
        ['hello'],
        [
          {
            "job_class" => "SomeWorker",
            "job_id" => "b4a577edbccf1d805744efa9",
            "provider_job_id" => nil,
            "queue_name" => "default",
            "arguments" => ["some", ["argument"]],
            "executions" => 0,
            "locale" => "en",
            "attempt_number" => 1
          },
          nil,
          'hello',
          12345678901234567890,
          ['nice']
        ],
        [
          '2021-05-13_09:59:37.57483 [35mrails-background-jobs : [0m{"severity":"ERROR","time":"2021-05-13T09:59:37.574Z"',
          'bonne journée - ขอให้มีความสุขในวันนี้ - một ngày mới tốt lành - 좋은 하루 되세요 - ごきげんよう',
          '🤝 - 🦊'
        ]
      ]
    end

    with_them do
      let(:payload) { base_payload.merge("args" => args) }

      it 'injects compressed data' do
        serialized_args = Sidekiq.dump_json(args)
        described_class.compress(payload, serialized_args)

        expect(payload['args'].length).to be(1)
        expect(payload['args'].first).to be_a(String)
        expect(payload['compressed']).to be(true)
        expect(payload['original_job_size_bytes']).to eql(serialized_args.bytesize)
        expect do
          Sidekiq.dump_json(payload)
        end.not_to raise_error
      end

      it 'can decompress the payload' do
        original_payload = payload.deep_dup

        described_class.compress(payload, Sidekiq.dump_json(args))
        described_class.decompress(payload)

        expect(payload).to eql(original_payload)
      end
    end
  end

  describe '.decompress' do
    context 'job payload is not compressed' do
      let(:payload) { base_payload.merge("args" => ['hello']) }

      it 'preserves the payload after decompression' do
        original_payload = payload.deep_dup

        described_class.decompress(payload)

        expect(payload).to eql(original_payload)
      end
    end

    context 'job payload is compressed with a default level' do
      let(:payload) do
        base_payload.merge(
          'args' => ['eF6LVspIzcnJV9JRKs8vyklRigUAMq0FqQ=='],
          'compressed' => true
        )
      end

      it 'decompresses and clean up the job payload' do
        described_class.decompress(payload)

        expect(payload['args']).to eql(%w[hello world])
        expect(payload).not_to have_key('compressed')
      end
    end

    context 'job payload is compressed with a different level' do
      let(:payload) do
        base_payload.merge(
          'args' => [Base64.strict_encode64(Zlib::Deflate.deflate(Sidekiq.dump_json(%w[hello world]), 9))],
          'compressed' => true
        )
      end

      it 'decompresses and clean up the job payload' do
        described_class.decompress(payload)

        expect(payload['args']).to eql(%w[hello world])
        expect(payload).not_to have_key('compressed')
      end
    end

    context 'job payload argument list is malformed' do
      let(:payload) do
        base_payload.merge(
          'args' => ['eNqLVspIzcnJV9JRKs8vyklRigUAMq0FqQ==', 'something else'],
          'compressed' => true
        )
      end

      it 'tracks the conflicting exception' do
        expect(::Gitlab::ErrorTracking).to receive(:track_and_raise_exception).with(
          be_a(::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor::PayloadDecompressionConflictError)
        )

        described_class.decompress(payload)

        expect(payload['args']).to eql(%w[hello world])
        expect(payload).not_to have_key('compressed')
      end
    end

    context 'job payload is not a valid base64 string' do
      let(:payload) do
        base_payload.merge(
          'args' => ['hello123'],
          'compressed' => true
        )
      end

      it 'raises an exception' do
        expect do
          described_class.decompress(payload)
        end.to raise_error(::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor::PayloadDecompressionError)
      end
    end

    context 'job payload compression does not contain a valid Gzip header' do
      let(:payload) do
        base_payload.merge(
          'args' => ['aGVsbG8='],
          'compressed' => true
        )
      end

      it 'raises an exception' do
        expect do
          described_class.decompress(payload)
        end.to raise_error(::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor::PayloadDecompressionError)
      end
    end

    context 'job payload compression does not contain a valid Gzip body' do
      let(:payload) do
        base_payload.merge(
          'args' => ["eNqLVspIzcnJVw=="],
          'compressed' => true
        )
      end

      it 'raises an exception' do
        expect do
          described_class.decompress(payload)
        end.to raise_error(::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor::PayloadDecompressionError)
      end
    end
  end
end
