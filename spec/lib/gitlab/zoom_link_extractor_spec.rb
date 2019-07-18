# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ZoomLinkExtractor do
  describe "#links" do
    using RSpec::Parameterized::TableSyntax

    where(:text, :links) do
      'issue text https://zoom.us/j/123 and https://zoom.us/s/1123433' | %w[https://zoom.us/j/123 https://zoom.us/s/1123433]
      'https://zoom.us/j/1123433 issue text' | %w[https://zoom.us/j/1123433]
      'issue https://zoom.us/my/1123433 text' | %w[https://zoom.us/my/1123433]
      'issue https://gitlab.com and https://gitlab.zoom.us/s/1123433' | %w[https://gitlab.zoom.us/s/1123433]
      'https://gitlab.zoom.us/j/1123433' | %w[https://gitlab.zoom.us/j/1123433]
      'https://gitlab.zoom.us/my/1123433' | %w[https://gitlab.zoom.us/my/1123433]
    end

    with_them do
      subject { described_class.new(text).links }

      it { is_expected.to eq(links) }
    end
  end
end
