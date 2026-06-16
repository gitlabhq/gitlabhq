# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::LargeMultipartParser, feature_category: :source_code_management do
  let(:boundary) { 'TestBoundary' }
  let(:content_type) { "multipart/form-data; boundary=#{boundary}" }

  def build_env(body)
    {
      'CONTENT_TYPE' => content_type,
      'CONTENT_LENGTH' => body.bytesize.to_s,
      'rack.input' => StringIO.new(body)
    }
  end

  def build_multipart_body(fields)
    parts = fields.map do |name, value|
      "--#{boundary}\r\n" \
        "Content-Disposition: form-data; name=\"#{name}\"\r\n" \
        "\r\n" \
        "#{value}\r\n"
    end

    (parts.join + "--#{boundary}--\r\n")
  end

  describe '.parse_multipart' do
    it 'parses simple text fields' do
      body = build_multipart_body('branch' => 'main', 'commit_message' => 'test')

      result = described_class.parse_multipart(build_env(body))

      expect(result).to eq({ 'branch' => 'main', 'commit_message' => 'test' })
    end

    it 'parses fields larger than 16 MB without raising' do
      large_content = 'x' * (17 * 1024 * 1024)
      body = build_multipart_body('content' => large_content)

      result = described_class.parse_multipart(build_env(body))

      expect(result['content']).to eq(large_content)
    end

    it 'confirms Rack::Multipart raises for the same input' do
      large_content = 'x' * (17 * 1024 * 1024)
      body = build_multipart_body('content' => large_content)

      expect do
        Rack::Multipart.parse_multipart(build_env(body))
      end.to raise_error(EOFError, /retained size limit/)
    end

    it 'raises when retained size exceeds CommitsUploader.max_request_size' do
      stub_const('Repositories::CommitsUploader::DEFAULT_MAX_REQUEST_SIZE', 18.megabytes)

      large_content = 'x' * (18.megabytes + 1)
      body = build_multipart_body('content' => large_content)

      expect do
        described_class.parse_multipart(build_env(body))
      end.to raise_error(EOFError, /retained size limit/)
    end

    it 'parses nested field names', :aggregate_failures do
      body = build_multipart_body(
        'branch' => 'main',
        'actions[][action]' => 'create',
        'actions[][file_path]' => 'test.rb',
        'actions[][content]' => 'puts 1'
      )

      result = described_class.parse_multipart(build_env(body))

      expect(result['branch']).to eq('main')
      expect(result['actions']).to be_an(Array)
      expect(result['actions'].first['action']).to eq('create')
      expect(result['actions'].first['file_path']).to eq('test.rb')
      expect(result['actions'].first['content']).to eq('puts 1')
    end

    it 'rejects file uploads via tempfile factory' do
      body = "--#{boundary}\r\n" \
        "Content-Disposition: form-data; name=\"file\"; filename=\"test.txt\"\r\n" \
        "Content-Type: text/plain\r\n" \
        "\r\n" \
        "file content\r\n" \
        "--#{boundary}--\r\n"

      env = build_env(body)
      env[Rack::RACK_MULTIPART_TEMPFILE_FACTORY] = ->(_, _) { raise 'file upload not supported' }

      expect do
        described_class.parse_multipart(env)
      end.to raise_error(RuntimeError, 'file upload not supported')
    end

    it 'sets RACK_TEMPFILES on the env after parsing' do
      body = build_multipart_body('branch' => 'main')
      env = build_env(body)

      described_class.parse_multipart(env)

      expect(env[Rack::RACK_TEMPFILES]).not_to be_nil
    end

    it 'handles a missing CONTENT_LENGTH header' do
      body = build_multipart_body('branch' => 'main')
      env = build_env(body)
      env.delete('CONTENT_LENGTH')

      expect(described_class.parse_multipart(env)).to eq({ 'branch' => 'main' })
    end

    it 'parses a zero-byte body without raising' do
      env = build_env('')

      expect { described_class.parse_multipart(env) }.not_to raise_error
    end

    it 'returns the same structure as Rack::Multipart for small inputs' do
      body = build_multipart_body(
        'branch' => 'main',
        'actions[][action]' => 'create',
        'actions[][file_path]' => 'test.rb',
        'actions[][content]' => 'puts 1'
      )

      custom_result = described_class.parse_multipart(build_env(body))
      rack_result = Rack::Multipart.parse_multipart(build_env(body))

      expect(custom_result).to eq(rack_result)
    end
  end

  describe 'Rack version compatibility' do
    it 'is compatible with the current Rack::Multipart::Parser API', :aggregate_failures do
      expect(Rack.release).to start_with('2.2.'),
        "Rack version has changed from 2.2.x to #{Rack.release}. " \
          "#{described_class} replicates Rack::Multipart.extract_multipart internals " \
          "and must be reviewed and updated for the new Rack version."

      expect(Rack::Multipart::Parser).to respond_to(:parse)
      expect(Rack::Multipart::Parser.method(:parse).arity).to eq(6)
    end
  end
end
