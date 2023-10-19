# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/rspec/env_mocking'

RSpec.describe RuboCop::Cop::RSpec::EnvMocking, feature_category: :tooling do
  offense_call_brackets_string_quotes = %(allow(ENV).to receive(:[]).with('FOO').and_return('bar'))
  offense_call_brackets_variables = %(allow(ENV).to receive(:[]).with(key).and_return(value))

  offense_call_fetch_string_quotes = %(allow(ENV).to receive(:fetch).with('FOO').and_return('bar'))
  offense_call_fetch_variables = %(allow(ENV).to receive(:fetch).with(key).and_return(value))

  offense_call_root_env_variables = %(allow(::ENV).to receive(:[]).with(key).and_return(value))
  offense_call_key_value_method_calls =
    %(allow(ENV).to receive(:[]).with(fetch_key(object)).and_return(fetch_value(object)))

  acceptable_mocking_other_methods = %(allow(ENV).to receive(:foo).with("key").and_return("value"))

  let(:source_file) { 'spec/foo_spec.rb' }

  shared_examples 'cop offense mocking the ENV constant correctable with stub_env' do |content, autocorrected_content|
    it "registers an offense for `#{content}` and corrects", :aggregate_failures do
      expect_offense(<<~CODE, content: content)
        %{content}
        ^{content} Don't mock the ENV, use `stub_env` instead.
      CODE

      expect_correction(<<~CODE)
        #{autocorrected_content}
      CODE
    end
  end

  context 'with mocking bracket calls ' do
    it_behaves_like 'cop offense mocking the ENV constant correctable with stub_env',
      offense_call_brackets_string_quotes, %(stub_env('FOO', 'bar'))
    it_behaves_like 'cop offense mocking the ENV constant correctable with stub_env',
      offense_call_brackets_variables, %(stub_env(key, value))
  end

  context 'with mocking fetch calls' do
    it_behaves_like 'cop offense mocking the ENV constant correctable with stub_env',
      offense_call_fetch_string_quotes, %(stub_env('FOO', 'bar'))
    it_behaves_like 'cop offense mocking the ENV constant correctable with stub_env',
      offense_call_fetch_variables, %(stub_env(key, value))
  end

  context 'with other special cases and variations' do
    it_behaves_like 'cop offense mocking the ENV constant correctable with stub_env',
      offense_call_root_env_variables, %(stub_env(key, value))
    it_behaves_like 'cop offense mocking the ENV constant correctable with stub_env',
      offense_call_key_value_method_calls, %(stub_env(fetch_key(object), fetch_value(object)))
  end

  context 'with acceptable cases' do
    it 'does not register an offense for mocking other methods' do
      expect_no_offenses(acceptable_mocking_other_methods)
    end
  end
end
