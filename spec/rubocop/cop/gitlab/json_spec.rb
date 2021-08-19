# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/json'

RSpec.describe RuboCop::Cop::Gitlab::Json do
  subject(:cop) { described_class.new }

  context 'when ::JSON is called' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class Foo
          def bar
            JSON.parse('{ "foo": "bar" }')
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid calling `JSON` directly. [...]
          end
        end
      RUBY
    end
  end

  context 'when ActiveSupport::JSON is called' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class Foo
          def bar
            ActiveSupport::JSON.parse('{ "foo": "bar" }')
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid calling `JSON` directly. [...]
          end
        end
      RUBY
    end
  end
end
