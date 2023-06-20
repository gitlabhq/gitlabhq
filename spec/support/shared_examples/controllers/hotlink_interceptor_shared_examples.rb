# frozen_string_literal: true

RSpec.shared_examples "hotlink interceptor" do
  let(:http_request) { nil }
  let(:headers) { nil }

  describe "DDOS prevention" do
    using RSpec::Parameterized::TableSyntax

    context "hotlinked as media" do
      where(:response_status, :accept_header) do
        # These are default formats in modern browsers, and IE
        :ok | "*/*"
        :ok | "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        :ok | "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
        :ok | "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        :ok | "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"
        :ok | "image/jpeg, application/x-ms-application, image/gif, application/xaml+xml, image/pjpeg, application/x-ms-xbap, application/x-shockwave-flash, application/msword, */*"
        :ok | "text/html, application/xhtml+xml, image/jxr, */*"
        :ok | "text/html, application/xml;q=0.9, application/xhtml+xml, image/png, image/webp, image/jpeg, image/gif, image/x-xbitmap, */*;q=0.1"

        # These are image request formats
        :not_acceptable | "image/webp,*/*"
        :not_acceptable | "image/png,image/*;q=0.8,*/*;q=0.5"
        :not_acceptable | "image/webp,image/apng,image/*,*/*;q=0.8"
        :not_acceptable | "image/png,image/svg+xml,image/*;q=0.8, */*;q=0.5"

        # Video request formats
        :not_acceptable | "video/webm,video/ogg,video/*;q=0.9,application/ogg;q=0.7,audio/*;q=0.6,*/*;q=0.5"

        # Audio request formats
        :not_acceptable | "audio/webm,audio/ogg,audio/wav,audio/*;q=0.9,application/ogg;q=0.7,video/*;q=0.6,*/*;q=0.5"

        # CSS request formats
        :not_acceptable | "text/css,*/*;q=0.1"
        :not_acceptable | "text/css"
        :not_acceptable | "text/css,*/*;q=0.1"

        # Invalid MIME definition
        :not_acceptable | "text/html, image/gif, image/jpeg, *; q=.2, */*; q=.2"
      end

      with_them do
        let(:headers) do
          { "Accept" => accept_header }
        end

        before do
          request.headers.merge!(headers) if request.present?
        end

        it "renders the response" do
          http_request

          expect(response).to have_gitlab_http_status(response_status)
        end
      end
    end

    context "hotlinked as a script" do
      where(:response_status, :fetch_mode) do
        # Standard navigation fetch modes
        :ok | "navigate"
        :ok | "nested-navigate"
        :ok | "same-origin"

        # Fetch modes when linking as JS
        :not_acceptable | "cors"
        :not_acceptable | "no-cors"
        :not_acceptable | "websocket"
      end

      with_them do
        let(:headers) do
          { "Sec-Fetch-Mode" => fetch_mode }
        end

        before do
          request.headers.merge!(headers) if request.present?
        end

        it "renders the response" do
          http_request

          expect(response).to have_gitlab_http_status(response_status)
        end
      end
    end
  end
end
