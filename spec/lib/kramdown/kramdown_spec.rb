# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Ensure kramdown detects invalid syntax highlighting formatters' do
  subject { Kramdown::Document.new(options + "\n" + code).to_html }

  let(:code) do
    <<-RUBY
~~~ ruby
    def what?
      42
    end
~~~
    RUBY
  end

  context 'with invalid formatter' do
    let(:options) { %({::options auto_ids="false" footnote_nr="5" syntax_highlighter="rouge" syntax_highlighter_opts="{formatter: CSV, line_numbers: true\\}" /}) }

    it 'falls back to standard HTML and disallows CSV' do
      expect(CSV).not_to receive(:new)
      expect(::Rouge::Formatters::HTML).to receive(:new).and_call_original

      expect(subject).to be_present
    end
  end

  context 'with valid formatter' do
    let(:options) { %({::options auto_ids="false" footnote_nr="5" syntax_highlighter="rouge" syntax_highlighter_opts="{formatter: HTMLLegacy\\}" /}) }

    it 'allows formatter' do
      expect(::Rouge::Formatters::HTMLLegacy).to receive(:new).and_call_original

      expect(subject).to be_present
    end
  end
end
