# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UrlHelper do
  describe '#escaped_url' do
    it 'escapes url' do
      expect(helper.escaped_url('https://example.com?param=test value')).to eq('https://example.com?param=test%20value')
    end

    it 'escapes XSS injection' do
      expect(helper.escaped_url('https://example.com/asset.js"+eval(alert(1))));</script>'))
        .to eq('https://example.com/asset.js%22+eval(alert(1))));%3C/script%3E')
    end

    it 'returns nil if url is nil' do
      expect(helper.escaped_url(nil)).to be_nil
    end
  end
end
