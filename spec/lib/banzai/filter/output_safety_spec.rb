# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::OutputSafety do
  subject do
    Class.new do
      include Banzai::Filter::OutputSafety
    end.new
  end

  let(:content) { '<pre><code>foo</code></pre>' }

  context 'when given HTML is safe' do
    let(:html) { content.html_safe }

    it 'returns safe HTML' do
      expect(subject.escape_once(html)).to eq(html)
    end
  end

  context 'when given HTML is not safe' do
    let(:html) { content }

    it 'returns escaped HTML' do
      expect(subject.escape_once(html)).to eq(ERB::Util.html_escape_once(html))
    end
  end
end
