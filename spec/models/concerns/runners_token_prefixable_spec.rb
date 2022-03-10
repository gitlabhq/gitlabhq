# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RunnersTokenPrefixable do
  describe 'runners token prefix' do
    subject { described_class::RUNNERS_TOKEN_PREFIX }

    it 'has the correct value' do
      expect(subject).to eq('GR1348941')
    end
  end
end
