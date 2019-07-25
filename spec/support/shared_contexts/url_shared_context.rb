# frozen_string_literal: true

shared_context 'invalid urls' do
  let(:urls_with_CRLF) do
    ["http://127.0.0.1:333/pa\rth",
     "http://127.0.0.1:333/pa\nth",
     "http://127.0a.0.1:333/pa\r\nth",
     "http://127.0.0.1:333/path?param=foo\r\nbar",
     "http://127.0.0.1:333/path?param=foo\rbar",
     "http://127.0.0.1:333/path?param=foo\nbar",
     "http://127.0.0.1:333/pa%0dth",
     "http://127.0.0.1:333/pa%0ath",
     "http://127.0a.0.1:333/pa%0d%0th",
     "http://127.0.0.1:333/pa%0D%0Ath",
     "http://127.0.0.1:333/path?param=foo%0Abar",
     "http://127.0.0.1:333/path?param=foo%0Dbar",
     "http://127.0.0.1:333/path?param=foo%0D%0Abar"]
  end
end
