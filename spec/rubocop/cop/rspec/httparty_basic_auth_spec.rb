# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/rspec/httparty_basic_auth'

RSpec.describe RuboCop::Cop::RSpec::HTTPartyBasicAuth, feature_category: :shared do
  context 'when passing `basic_auth: { user: ... }`' do
    it 'registers an offense and corrects', :aggregate_failures do
      expect_offense(<<~SOURCE, 'spec/foo.rb')
        HTTParty.put(
          url,
          basic_auth: { user: user, password: token },
                        ^^^^ #{described_class::MESSAGE}
          body: body
        )
      SOURCE

      expect_correction(<<~SOURCE)
        HTTParty.put(
          url,
          basic_auth: { username: user, password: token },
          body: body
        )
      SOURCE
    end
  end

  context 'when passing `basic_auth: { username: ... }`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~SOURCE, 'spec/frontend/fixtures/foo.rb')
        HTTParty.put(
          url,
          basic_auth: { username: user, password: token },
          body: body
        )
      SOURCE
    end
  end
end
