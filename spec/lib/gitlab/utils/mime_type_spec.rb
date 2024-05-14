# frozen_string_literal: true

require "fast_spec_helper"
require "rspec/parameterized"

RSpec.describe Gitlab::Utils::MimeType do
  describe ".from_io" do
    subject { described_class.from_io(io) }

    context "input isn't an IO" do
      let(:io) { "test" }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "input is a file" do
      using RSpec::Parameterized::TableSyntax

      where(:fixture, :mime_type) do
        "banana_sample.gif"                 | "image/gif"
        "rails_sample.jpg"                  | "image/jpeg"
        "rails_sample.png"                  | "image/png"
        "rails_sample.bmp"                  | "image/bmp"
        "rails_sample.tif"                  | "image/tiff"
        "sample.ico"                        | "image/vnd.microsoft.icon"
        "blockquote_fence_legacy_before.md" | "text/plain"
        "csv_empty.csv"                     | "application/x-empty"
      end

      with_them do
        let(:io) { File.open(File.join(__dir__, "../../../fixtures", fixture)) }

        it { is_expected.to eq(mime_type) }
      end
    end
  end

  describe ".from_string" do
    subject { described_class.from_string(str) }

    context "input isn't a string" do
      let(:str) { nil }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "input is a string" do
      let(:str) { "plain text" }

      it { is_expected.to eq('text/plain') }
    end
  end
end
