# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VersionCheck do
  describe '.url' do
    it 'returns the correct URL' do
      expect(described_class.url).to match(%r{\A#{Regexp.escape(described_class.host)}/check\.svg\?gitlab_info=\w+})
    end
  end
end
