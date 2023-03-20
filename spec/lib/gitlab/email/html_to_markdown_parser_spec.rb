# frozen_string_literal: true

require 'kramdown'
require 'html2text'
require 'fast_spec_helper'
require 'support/helpers/fixture_helpers'

RSpec.describe Gitlab::Email::HtmlToMarkdownParser, feature_category: :service_desk do
  include FixtureHelpers

  subject { described_class.convert(html) }

  describe '.convert' do
    let(:html) { fixture_file("lib/gitlab/email/basic.html") }

    it 'parses html correctly' do
      expect(subject).to eq(
        <<~BODY.chomp
          Hello, World!
          This is some e-mail content. Even though it has whitespace and newlines, the e-mail converter will handle it correctly.
          *Even* mismatched tags.
          A div
          Another div
          A div
          **within** a div

          Another line
          Yet another line
          [A link](http://foo.com)
          <details>
          <summary>
          One</summary>
          Some details</details>

          <details>
          <summary>
          Two</summary>
          Some details</details>

          ![Miro](http://img.png)
          Col A	Col B
          Data A1	Data B1
          Data A2	Data B2
          Data A3	Data B4
          Total A	Total B
        BODY
      )
    end
  end
end
