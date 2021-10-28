# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Unicode do
  describe described_class::BIDI_REGEXP do
    using RSpec::Parameterized::TableSyntax

    where(:bidi_string, :match) do
      "\u2066"       | true # left-to-right isolate
      "\u2067"       | true # right-to-left isolate
      "\u2068"       | true # first strong isolate
      "\u2069"       | true # pop directional isolate
      "\u202a"       | true # left-to-right embedding
      "\u202b"       | true # right-to-left embedding
      "\u202c"       | true # pop directional formatting
      "\u202d"       | true # left-to-right override
      "\u202e"       | true # right-to-left override
      "\u2066foobar" | true
      ""             | false
      "foo"          | false
      "\u2713"       | false # checkmark
    end

    with_them do
      let(:utf8_string) { bidi_string.encode("utf-8") }

      it "matches only the bidi characters" do
        expect(utf8_string.match?(subject)).to eq(match)
      end
    end
  end
end
