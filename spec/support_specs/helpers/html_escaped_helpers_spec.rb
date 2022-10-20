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

  describe '#ensure_no_html_escaped_tags!' do
    subject { |example| described_class.ensure_no_html_escaped_tags!(content, example) }

    context 'when content contains HTML escaped chars' do
      let(:content) { 'See &lt;a href=""&gt;Link&lt;/a&gt;' }

      it 'raises an exception' do
        parts = [
          'The following string contains HTML escaped tags:',
          'See «&lt;a» href=""&gt;Link&lt;/a&gt;',
          'This check can be disabled via:',
          %(it "raises an exception", :skip_html_escaped_tags_check do)
        ]

        regexp = Regexp.new(parts.join('.*'), Regexp::MULTILINE)

        expect { subject }.to raise_error(regexp)
      end
    end

    context 'when content does not contain HTML escaped tags' do
      let(:content) { 'See <a href="">Link</a>' }

      it 'does not raise anything' do
        expect(subject).to be_nil
      end
    end
  end
end
