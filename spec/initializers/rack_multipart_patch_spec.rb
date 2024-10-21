# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rack::Multipart do # rubocop:disable RSpec/SpecFilePathFormat
  def multipart_fixture(name, length, boundary = "AaB03x")
    data = <<EOF
--#{boundary}\r
content-disposition: form-data; name="reply"\r
\r
yes\r
--#{boundary}\r
content-disposition: form-data; name="fileupload"; filename="dj.jpg"\r
Content-Type: image/jpeg\r
Content-Transfer-Encoding: base64\r
\r
/9j/4AAQSkZJRgABAQAAAQABAAD//gA+Q1JFQVRPUjogZ2QtanBlZyB2MS4wICh1c2luZyBJSkcg\r
--#{boundary}--\r
EOF

    type = %(multipart/form-data; boundary=#{boundary})

    length ||= data.bytesize

    {
      "CONTENT_TYPE" => type,
      "CONTENT_LENGTH" => length.to_s,
      input: StringIO.new(data)
    }
  end

  context 'with Content-Length under the limit' do
    it 'extracts multipart message' do
      env = Rack::MockRequest.env_for("/", multipart_fixture(:text, nil))

      expect(described_class).to receive(:log_large_multipart?).and_call_original
      expect(described_class).not_to receive(:log_multipart_warning)
      params = described_class.parse_multipart(env)

      expect(params.keys).to include(*%w[reply fileupload])
    end
  end

  context 'with Content-Length over the limit' do
    shared_examples 'logs multipart message' do
      it 'extracts multipart message' do
        env = Rack::MockRequest.env_for("/", multipart_fixture(:text, length))

        expect(described_class).to receive(:log_large_multipart?).and_return(true)
        expect(described_class).to receive(:log_multipart_warning).and_call_original
        expect(described_class).to receive(:log_warn).with({
                                                             message: 'Large multipart body detected',
                                                             path: '/',
                                                             content_length: anything,
                                                             correlation_id: anything
                                                           })
        params = described_class.parse_multipart(env)

        expect(params.keys).to include(*%w[reply fileupload])
      end
    end

    context 'from environment' do
      let(:length) { 1001 }

      before do
        stub_env('RACK_MULTIPART_LOGGING_BYTES', 1000)
      end

      it_behaves_like 'logs multipart message'
    end

    context 'default limit' do
      let(:length) { 100_000_001 }

      it_behaves_like 'logs multipart message'
    end
  end
end
