# frozen_string_literal: true

require 'fast_spec_helper'
require 'rack'
require 'tempfile'

RSpec.describe Gitlab::Middleware::RackMultipartTempfileFactory do
  let(:app) do
    ->(env) do
      params = Rack::Request.new(env).params

      if params['file']
        [200, { 'Content-Type' => params['file'][:type] }, [params['file'][:tempfile].read]]
      else
        [204, {}, []]
      end
    end
  end

  let(:file_contents) { '/9j/4AAQSkZJRgABAQAAAQABAAD//gA+Q1JFQVRPUjogZ2QtanBlZyB2MS4wICh1c2luZyBJSkcg' }

  let(:multipart_fixture) do
    boundary = 'AaB03x'
    data = <<~DATA
      --#{boundary}\r
      Content-Disposition: form-data; name="file"; filename="dj.jpg"\r
      Content-Type: image/jpeg\r
      Content-Transfer-Encoding: base64\r
      \r
      #{file_contents}\r
      --#{boundary}--\r
    DATA

    {
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}",
      'CONTENT_LENGTH' => data.bytesize.to_s,
      input: StringIO.new(data)
    }
  end

  subject { described_class.new(app) }

  context 'for a multipart request' do
    let(:env) { Rack::MockRequest.env_for('/', multipart_fixture) }

    it 'immediately unlinks the temporary file' do
      tempfile = Tempfile.new('foo')

      expect(tempfile.path).not_to be(nil)
      expect(Rack::Multipart::Parser::TEMPFILE_FACTORY).to receive(:call).and_return(tempfile)
      expect(tempfile).to receive(:unlink).and_call_original

      subject.call(env)

      expect(tempfile.path).to be(nil)
    end

    it 'processes the request as normal' do
      expect(subject.call(env)).to eq([200, { 'Content-Type' => 'image/jpeg' }, [file_contents]])
    end
  end

  context 'for a regular request' do
    let(:env) { Rack::MockRequest.env_for('/', params: { 'foo' => 'bar' }) }

    it 'does nothing' do
      expect(Rack::Multipart::Parser::TEMPFILE_FACTORY).not_to receive(:call)
      expect(subject.call(env)).to eq([204, {}, []])
    end
  end
end
