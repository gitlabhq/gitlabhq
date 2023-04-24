# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/gitlab/keys_first_and_values_first'

RSpec.describe RuboCop::Cop::Gitlab::KeysFirstAndValuesFirst do
  let(:msg) { described_class::MSG }

  shared_examples 'inspect use of keys or values first' do |method, autocorrect|
    describe ".#{method}.first" do
      it 'flags and autocorrects' do
        expect_offense(<<~RUBY, method: method, autocorrect: autocorrect)
          hash.%{method}.first
               _{method} ^^^^^ Prefer `.%{autocorrect}.first` over `.%{method}.first`. [...]
          var = {a: 1}; var.%{method}.first
                            _{method} ^^^^^ Prefer `.%{autocorrect}.first` over `.%{method}.first`. [...]
          {a: 1}.%{method}.first
                 _{method} ^^^^^ Prefer `.%{autocorrect}.first` over `.%{method}.first`. [...]
          CONST.%{method}.first
                _{method} ^^^^^ Prefer `.%{autocorrect}.first` over `.%{method}.first`. [...]
          ::CONST.%{method}.first
                  _{method} ^^^^^ Prefer `.%{autocorrect}.first` over `.%{method}.first`. [...]
        RUBY

        expect_correction(<<~RUBY)
          hash.#{autocorrect}.first
          var = {a: 1}; var.#{autocorrect}.first
          {a: 1}.#{autocorrect}.first
          CONST.#{autocorrect}.first
          ::CONST.#{autocorrect}.first
        RUBY
      end

      it 'does not flag unrelated code' do
        expect_no_offenses(<<~RUBY)
          array.first
          hash.#{method}.last
          hash.#{method}
          #{method}.first
          1.#{method}.first
          'string'.#{method}.first
        RUBY
      end
    end
  end

  it_behaves_like 'inspect use of keys or values first', :keys, :each_key
  it_behaves_like 'inspect use of keys or values first', :values, :each_value
end
