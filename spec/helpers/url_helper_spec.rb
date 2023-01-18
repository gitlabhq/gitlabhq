# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UrlHelper, feature_category: :integrations do
  describe '#escaped_url' do
    it 'escapes url' do
      expect(helper.escaped_url('https://example.com?param=test value')).to eq('https://example.com?param=test%20value')
    end

    it 'escapes XSS injection' do
      expect(helper.escaped_url('https://example.com?injected_here"+eval(1)+"'))
      .to eq('https://example.com?injected_here%22+eval(1)+%22')
    end

    it 'returns nil if url is nil' do
      expect(helper.escaped_url(nil)).to be_nil
    end

    it 'returns nil when url is invalid' do
      expect(helper.escaped_url('https://?&*^invalid-url'))
      .to be_nil
    end
  end
end
