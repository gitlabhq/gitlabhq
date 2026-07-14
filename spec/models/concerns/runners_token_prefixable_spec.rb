# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RunnersTokenPrefixable, feature_category: :system_access do
  describe 'runners token prefix' do
    subject(:runners_token_prefix) { described_class::RUNNERS_TOKEN_PREFIX }

    it 'has the correct value' do
      expect(runners_token_prefix).to eq('GR1348941')
    end
  end
end
