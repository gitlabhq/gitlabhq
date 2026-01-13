# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/json_safe_parse'

RSpec.describe RuboCop::Cop::Gitlab::JsonSafeParse, feature_category: :tooling do
  describe 'autocorrection' do
    context 'when using Gitlab::Json.parse' do
      it 'corrects to Gitlab::Json.safe_parse' do
        expect_offense(<<~RUBY)
          Gitlab::Json.parse(user_input)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ [...]
        RUBY

        expect_correction(<<~RUBY)
          Gitlab::Json.safe_parse(user_input)
        RUBY
      end
    end

    context 'when using ::Gitlab::Json.parse' do
      it 'corrects to Gitlab::Json.safe_parse' do
        expect_offense(<<~RUBY)
          ::Gitlab::Json.parse(data)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^ [...]
        RUBY

        expect_correction(<<~RUBY)
          Gitlab::Json.safe_parse(data)
        RUBY
      end
    end

    context 'when using Gitlab::Json.parse!' do
      it 'corrects to Gitlab::Json.safe_parse' do
        expect_offense(<<~RUBY)
          Gitlab::Json.parse!(input)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^ [...]
        RUBY

        expect_correction(<<~RUBY)
          Gitlab::Json.safe_parse(input)
        RUBY
      end
    end

    context 'when using Gitlab::Json.load' do
      it 'corrects to Gitlab::Json.safe_parse' do
        expect_offense(<<~RUBY)
          Gitlab::Json.load(string)
          ^^^^^^^^^^^^^^^^^^^^^^^^^ [...]
        RUBY

        expect_correction(<<~RUBY)
          Gitlab::Json.safe_parse(string)
        RUBY
      end
    end

    context 'when using Gitlab::Json.decode' do
      it 'corrects to Gitlab::Json.safe_parse' do
        expect_offense(<<~RUBY)
          Gitlab::Json.decode(json_string)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ [...]
        RUBY

        expect_correction(<<~RUBY)
          Gitlab::Json.safe_parse(json_string)
        RUBY
      end
    end

    context 'when using parse with multiple arguments' do
      it 'preserves all arguments' do
        expect_offense(<<~RUBY)
          Gitlab::Json.parse(data, symbolize_names: true)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ [...]
        RUBY

        expect_correction(<<~RUBY)
          Gitlab::Json.safe_parse(data, symbolize_names: true)
        RUBY
      end
    end

    context 'when in an EE file' do
      it 'uses :: prefix' do
        expect_offense(<<~RUBY, '/path/to/ee/foo.rb')
          class Foo
            def bar
              Gitlab::Json.parse(data)
              ^^^^^^^^^^^^^^^^^^^^^^^^ [...]
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          class Foo
            def bar
              ::Gitlab::Json.safe_parse(data)
            end
          end
        RUBY
      end
    end
  end

  describe 'non-offenses' do
    it 'does not flag Gitlab::Json.safe_parse' do
      expect_no_offenses(<<~RUBY)
        Gitlab::Json.safe_parse(user_input)
      RUBY
    end

    it 'does not flag Gitlab::Json.safe_parse with options' do
      expect_no_offenses(<<~RUBY)
        Gitlab::Json.safe_parse(data, parse_limits: { max_depth: 10 })
      RUBY
    end

    it 'does not flag Gitlab::Json.generate' do
      expect_no_offenses(<<~RUBY)
        Gitlab::Json.generate(hash)
      RUBY
    end

    it 'does not flag Gitlab::Json.dump' do
      expect_no_offenses(<<~RUBY)
        Gitlab::Json.dump(object)
      RUBY
    end

    it 'does not flag JSON.parse (handled by Gitlab/Json cop)' do
      expect_no_offenses(<<~RUBY)
        JSON.parse(string)
      RUBY
    end

    it 'does not flag other parse methods' do
      expect_no_offenses(<<~RUBY)
        YAML.parse(string)
        SomeClass.parse(string)
      RUBY
    end

    it 'does not flag Gitlab::Json.pretty_generate' do
      expect_no_offenses(<<~RUBY)
        Gitlab::Json.pretty_generate(hash)
      RUBY
    end
  end
end
