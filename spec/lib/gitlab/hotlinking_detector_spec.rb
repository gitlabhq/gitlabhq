# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::HotlinkingDetector do
  describe ".intercept_hotlinking?" do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.intercept_hotlinking?(request) }

    let(:request) { double("request", headers: headers) }
    let(:headers) { {} }

    context "hotlinked as media" do
      where(:return_value, :accept_header) do
        # These are default formats in modern browsers, and IE
        false | "*/*"
        false | "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        false | "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
        false | "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        false | "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"
        false | "image/jpeg, application/x-ms-application, image/gif, application/xaml+xml, image/pjpeg, application/x-ms-xbap, application/x-shockwave-flash, application/msword, */*"
        false | "text/html, application/xhtml+xml, image/jxr, */*"
        false | "text/html, application/xml;q=0.9, application/xhtml+xml, image/png, image/webp, image/jpeg, image/gif, image/x-xbitmap, */*;q=0.1"

        # These are image request formats
        true | "image/webp,*/*"
        true | "image/png,image/*;q=0.8,*/*;q=0.5"
        true | "image/webp,image/apng,image/*,*/*;q=0.8"
        true | "image/png,image/svg+xml,image/*;q=0.8, */*;q=0.5"

        # Video request formats
        true | "video/webm,video/ogg,video/*;q=0.9,application/ogg;q=0.7,audio/*;q=0.6,*/*;q=0.5"

        # Audio request formats
        true | "audio/webm,audio/ogg,audio/wav,audio/*;q=0.9,application/ogg;q=0.7,video/*;q=0.6,*/*;q=0.5"

        # CSS request formats
        true | "text/css,*/*;q=0.1"
        true | "text/css"
        true | "text/css,*/*;q=0.1"

        # Invalid MIME definition
        true | "text/html, image/gif, image/jpeg, *; q=.2, */*; q=.2"
      end

      with_them do
        let(:headers) do
          { "Accept" => accept_header }
        end

        it { is_expected.to be(return_value) }
      end
    end

    context "hotlinked as a script" do
      where(:return_value, :fetch_mode) do
        # Standard navigation fetch modes
        false | "navigate"
        false | "nested-navigate"
        false | "same-origin"

        # Fetch modes when linking as JS
        true | "cors"
        true | "no-cors"
        true | "websocket"
      end

      with_them do
        let(:headers) do
          { "Sec-Fetch-Mode" => fetch_mode }
        end

        it { is_expected.to be(return_value) }
      end
    end
  end
end
