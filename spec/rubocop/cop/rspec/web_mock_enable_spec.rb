# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/rspec/web_mock_enable'

RSpec.describe RuboCop::Cop::RSpec::WebMockEnable do
  context 'when calling WebMock.disable_net_connect!' do
    it 'registers an offence and autocorrects it' do
      expect_offense(<<~RUBY)
        WebMock.disable_net_connect!(allow_localhost: true)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use webmock_enable! instead of calling WebMock.disable_net_connect! directly.
      RUBY

      expect_correction(<<~RUBY)
        webmock_enable!
      RUBY
    end
  end
end
