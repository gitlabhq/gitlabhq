# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../rubocop/cop/rspec/httparty_basic_auth'

RSpec.describe RuboCop::Cop::RSpec::HTTPartyBasicAuth do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'when passing `basic_auth: { user: ... }`' do
    it 'registers an offence' do
      expect_offense(<<~SOURCE, 'spec/foo.rb')
        HTTParty.put(
          url,
          basic_auth: { user: user, password: token },
                        ^^^^ #{described_class::MESSAGE}
          body: body
        )
      SOURCE
    end

    it 'can autocorrect the source' do
      bad  = 'HTTParty.put(url, basic_auth: { user: user, password: token })'
      good = 'HTTParty.put(url, basic_auth: { username: user, password: token })'
      expect(autocorrect_source(bad)).to eq(good)
    end
  end

  context 'when passing `basic_auth: { username: ... }`' do
    it 'does not register an offence' do
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
