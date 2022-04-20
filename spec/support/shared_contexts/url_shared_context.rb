# frozen_string_literal: true

RSpec.shared_context 'valid urls with CRLF' do
  let(:valid_urls_with_crlf) do
    [
      "http://example.com/pa%0dth",
      "http://example.com/pa%0ath",
      "http://example.com/pa%0d%0th",
      "http://example.com/pa%0D%0Ath",
      "http://gitlab.com/path?param=foo%0Abar",
      "https://gitlab.com/path?param=foo%0Dbar",
      "http://example.org:1024/path?param=foo%0D%0Abar",
      "https://storage.googleapis.com/bucket/import_export_upload/import_file/57265/express.tar.gz?GoogleAccessId=hello@example.org&Signature=ABCD%0AEFGHik&Expires=1634663304"
    ]
  end
end

RSpec.shared_context 'invalid urls' do
  let(:urls_with_crlf) do
    [
      "git://example.com/pa%0dth",
      "git://example.com/pa%0ath",
      "git://example.com/pa%0d%0th",
      "http://example.com/pa\rth",
      "http://example.com/pa\nth",
      "http://example.com/pa\r\nth",
      "http://example.com/path?param=foo\r\nbar",
      "http://example.com/path?param=foo\rbar",
      "http://example.com/path?param=foo\nbar"
    ]
  end
end
