# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe GenerateLetsEncryptPrivateKey do
  describe '#up' do
    it 'does not fail' do
      expect do
        described_class.new.up
      end.not_to raise_error
    end
  end
end
