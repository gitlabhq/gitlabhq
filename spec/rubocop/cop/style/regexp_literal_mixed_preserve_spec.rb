# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/style/regexp_literal_mixed_preserve'

# This spec contains only relevant examples.
#
# See also https://github.com/rubocop/rubocop/pull/9688
RSpec.describe RuboCop::Cop::Style::RegexpLiteralMixedPreserve, :config do
  let(:config) do
    supported_styles = { 'SupportedStyles' => %w[slashes percent_r mixed mixed_preserve] }
    RuboCop::Config.new(
      'Style/PercentLiteralDelimiters' => percent_literal_delimiters_config,
      'Style/RegexpLiteralMixedPreserve' => cop_config.merge(supported_styles)
    )
  end

  let(:percent_literal_delimiters_config) { { 'PreferredDelimiters' => { '%r' => '{}' } } }

  context 'when EnforcedStyle is set to mixed_preserve' do
    let(:cop_config) { { 'EnforcedStyle' => 'mixed_preserve' } }

    describe 'a single-line `//` regex without slashes' do
      it 'is accepted' do
        expect_no_offenses('foo = /a/')
      end
    end

    describe 'a single-line `//` regex with slashes' do
      it 'registers an offense and corrects' do
        expect_offense(<<~'RUBY')
          foo = /home\//
                ^^^^^^^^ Use `%r` around regular expression.
        RUBY

        expect_correction(<<~'RUBY')
          foo = %r{home/}
        RUBY
      end

      describe 'when configured to allow inner slashes' do
        before do
          cop_config['AllowInnerSlashes'] = true
        end

        it 'is accepted' do
          expect_no_offenses('foo = /home\\//')
        end
      end
    end

    describe 'a multi-line `//` regex without slashes' do
      it 'is accepted' do
        expect_no_offenses(<<~'RUBY')
          foo = /
            foo
            bar
          /x
        RUBY
      end
    end

    describe 'a multi-line `//` regex with slashes' do
      it 'registers an offense and corrects' do
        expect_offense(<<~'RUBY')
          foo = /
                ^ Use `%r` around regular expression.
            https?:\/\/
            example\.com
          /x
        RUBY

        expect_correction(<<~'RUBY')
          foo = %r{
            https?://
            example\.com
          }x
        RUBY
      end
    end

    describe 'a single-line %r regex without slashes' do
      it 'is accepted' do
        expect_no_offenses(<<~RUBY)
          foo = %r{a}
        RUBY
      end
    end

    describe 'a single-line %r regex with slashes' do
      it 'is accepted' do
        expect_no_offenses('foo = %r{home/}')
      end

      describe 'when configured to allow inner slashes' do
        before do
          cop_config['AllowInnerSlashes'] = true
        end

        it 'is accepted' do
          expect_no_offenses(<<~RUBY)
            foo = %r{home/}
          RUBY
        end
      end
    end

    describe 'a multi-line %r regex without slashes' do
      it 'is accepted' do
        expect_no_offenses(<<~RUBY)
          foo = %r{
            foo
            bar
          }x
        RUBY
      end
    end

    describe 'a multi-line %r regex with slashes' do
      it 'is accepted' do
        expect_no_offenses(<<~RUBY)
          foo = %r{
            https?://
            example\.com
          }x
        RUBY
      end
    end
  end
end
