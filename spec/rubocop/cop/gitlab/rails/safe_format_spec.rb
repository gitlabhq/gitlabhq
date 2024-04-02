# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../../rubocop/cop/gitlab/rails/safe_format'

RSpec.describe RuboCop::Cop::Gitlab::Rails::SafeFormat, feature_category: :tooling do
  shared_examples 'safe formatted externalized string' do |method:, condition: ""|
    context "for gettext method `#{method}(...)#{condition}`" do
      context 'with String#% and hash arg' do
        it 'flags and autocorrects externalized strings' do
          expect_offense(<<~RUBY, method: method, condition: condition)
            %{method}('%{a}string %{open}foo%{close}').html_safe % { a: '1'.html_safe, open: '<b>'.html_safe, close: '</b>'.html_safe }%{condition}
            _{method}                                            ^ Use `safe_format` [...]

            html_escape(%{method}('%{a}string %{open}foo%{close}').html_safe) %
                        _{method}                                             ^ Use `safe_format` [...]
              { a: '1'.html_safe, open: '<b>'.html_safe, close: '</b>'.html_safe }%{condition}
          RUBY

          expect_correction(<<~RUBY)
            safe_format(#{method}('%{a}string %{open}foo%{close}'), tag_pair(tag.b, :open, :close), a: '1'.html_safe)#{condition}

            safe_format(#{method}('%{a}string %{open}foo%{close}'), tag_pair(tag.b, :open, :close), a: '1'.html_safe)#{condition}
          RUBY
        end
      end

      context 'with String#% and array arg' do
        it 'flags and autocorrects externalized strings' do
          expect_offense(<<~RUBY, method: method, condition: condition)
            %{method}('string %sfoo%s').html_safe % [ '<b>'.html_safe, '</b>'.html_safe ]%{condition}
            _{method}                             ^ Use `safe_format` [...]

            html_escape(%{method}('string %sfoo%s').html_safe) % ['<b>'.html_safe, '</b>'.html_safe]%{condition}
                        _{method}                              ^ Use `safe_format` [...]
          RUBY

          expect_correction(<<~RUBY)
            safe_format(#{method}('string %sfoo%s'), '<b>'.html_safe, '</b>'.html_safe)#{condition}

            safe_format(#{method}('string %sfoo%s'), '<b>'.html_safe, '</b>'.html_safe)#{condition}
          RUBY
        end
      end

      context 'with String#% and bare arg' do
        it 'flags and autocorrects externalized strings' do
          expect_offense(<<~RUBY, method: method, condition: condition)
            %{method}('string %sfoo').html_safe % '<b>'.html_safe%{condition}
            _{method}                           ^ Use `safe_format` [...]

            html_escape(%{method}('string %sfoo').html_safe) % '<b>'.html_safe%{condition}
                        _{method}                            ^ Use `safe_format` [...]
          RUBY

          expect_correction(<<~RUBY)
            safe_format(#{method}('string %sfoo'), '<b>'.html_safe)#{condition}

            safe_format(#{method}('string %sfoo'), '<b>'.html_safe)#{condition}
          RUBY
        end
      end

      context 'with String#% and no html_safe' do
        it 'does not flag' do
          expect_no_offenses(<<~RUBY)
            #{method}('string %{name}') % { name: name }#{condition}
          RUBY
        end
      end

      context 'with String#format and hash arg' do
        it 'flags and autocorrects externalized strings' do
          expect_offense(<<~RUBY, method: method, condition: condition)
            format(%{method}('%{a}string %{open}foo%{close}').html_safe, a: '1'.html_safe, open: '<b>'.html_safe, close: '</b>'.html_safe)%{condition}
            ^^^^^^ Use `safe_format` [...]

            html_escape(format(%{method}('%{a}string %{open}foo%{close}').html_safe, a: '1'.html_safe, open: '<b>'.html_safe, close: '</b>'.html_safe))%{condition}
                        ^^^^^^ Use `safe_format` [...]
          RUBY

          expect_correction(<<~RUBY)
            safe_format(#{method}('%{a}string %{open}foo%{close}'), tag_pair(tag.b, :open, :close), a: '1'.html_safe)#{condition}

            safe_format(#{method}('%{a}string %{open}foo%{close}'), tag_pair(tag.b, :open, :close), a: '1'.html_safe)#{condition}
          RUBY
        end
      end

      context 'with String#format and no arg' do
        it 'flags and autocorrects externalized strings' do
          expect_offense(<<~RUBY, method: method, condition: condition)
            format(%{method}('string').html_safe)%{condition}
            ^^^^^^ Use `safe_format` [...]

            html_escape(format(%{method}('string').html_safe))%{condition}
                        ^^^^^^ Use `safe_format` [...]
          RUBY

          expect_correction(<<~RUBY)
            safe_format(#{method}('string'))#{condition}

            safe_format(#{method}('string'))#{condition}
          RUBY
        end
      end

      context 'with String#format and no html_safe' do
        it 'does not flag' do
          expect_no_offenses(<<~RUBY)
            format(#{method}('string %{name}'), name: name)#{condition}
          RUBY
        end
      end

      context 'with bare calls' do
        it 'flags and autocorrects externalized strings' do
          expect_offense(<<~RUBY, method: method, condition: condition)
            %{method}('string').html_safe%{condition}
            ^{method} Use `safe_format` [...]

            html_escape(%{method}('string').html_safe)%{condition}
                        ^{method} Use `safe_format` [...]
          RUBY

          expect_correction(<<~RUBY)
            safe_format(#{method}('string'))#{condition}

            safe_format(#{method}('string'))#{condition}
          RUBY
        end

        it 'does not flag' do
          expect_no_offenses(<<~RUBY)
            #{method}('string')#{condition}
          RUBY
        end
      end
    end
  end

  it_behaves_like 'safe formatted externalized string', method: :_
  it_behaves_like 'safe formatted externalized string', method: :_, condition: ' if cond'
  it_behaves_like 'safe formatted externalized string', method: :s_
  it_behaves_like 'safe formatted externalized string', method: :s_, condition: ' unless cond'
  it_behaves_like 'safe formatted externalized string', method: :n_
  it_behaves_like 'safe formatted externalized string', method: :n_, condition: ' if cond'
  it_behaves_like 'safe formatted externalized string', method: :N_
  it_behaves_like 'safe formatted externalized string', method: :N_, condition: ' unless cond'
end
