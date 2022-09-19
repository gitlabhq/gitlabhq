# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require_relative '../../support/helpers/html_escaped_helpers'

RSpec.describe HtmlEscapedHelpers do
  using RSpec::Parameterized::TableSyntax

  describe '#match_html_escaped_tags' do
    let(:actual_match) { actual_match_data && actual_match_data[0] }

    subject(:actual_match_data) { described_class.match_html_escaped_tags(content) }

    where(:content, :expected_match) do
      nil                     | nil
      ''                      | nil
      '<a href'               | nil
      '<span href'            | nil
      '</a>'                  | nil
      '&lt;a href'            | '&lt;a'
      '&lt;span href'         | '&lt;span'
      '&lt; span'             | '&lt; span'
      'some text &lt;a href'  | '&lt;a'
      'some text "&lt;a href' | '&lt;a'
      '&lt;/a&glt;'           | '&lt;/a'
      '&lt;/span&gt;'         | '&lt;/span'
      '&lt; / span&gt;'       | '&lt; / span'
      'title="&lt;a href'     | nil
      'title=  "&lt;a href'   | nil
      "title=  '&lt;a href"   | nil
      "title=  '&lt;/a"       | nil
      "title=  '&lt;/span"    | nil
      'title="foo">&lt;a'     | '&lt;a'
      "title='foo'>\n&lt;a"   | '&lt;a'
    end

    with_them do
      specify { expect(actual_match).to eq(expected_match) }
    end
  end
end
