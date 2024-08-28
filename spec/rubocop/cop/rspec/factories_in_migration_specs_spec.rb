# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/rspec/factories_in_migration_specs'

RSpec.describe RuboCop::Cop::RSpec::FactoriesInMigrationSpecs do
  shared_examples 'an offensive factory call' do |namespace|
    %i[build build_list create create_list attributes_for].each do |forbidden_method|
      namespaced_forbidden_method = "#{namespace}#{forbidden_method}"

      it "registers an offense for #{namespaced_forbidden_method} with one arg" do
        code = <<-RUBY
        describe 'foo' do
          let(:user) { %{namespaced_method}(:user) }
                       ^{namespaced_method}^^^^^^^ Don't use FactoryBot.%{method} in migration specs, use `table` instead.
        end
        RUBY

        expect_offense(code, method: forbidden_method, namespaced_method: namespaced_forbidden_method)
      end

      it "registers an offense for #{namespaced_forbidden_method} with multiple args" do
        code = <<-RUBY
        describe 'foo' do
          let(:user) { %{namespaced_method}(:user, name: name) }
                       ^{namespaced_method}^^^^^^^^^^^^^^^^^^^ Don't use FactoryBot.%{method} in migration specs, use `table` instead.
        end
        RUBY

        expect_offense(code, method: forbidden_method, namespaced_method: namespaced_forbidden_method)
      end

      it "does not create an offense for #{namespaced_forbidden_method} with no args" do
        expect_no_offenses(<<~RUBY)
          let(:id) { #{namespaced_forbidden_method}.id }
        RUBY
      end
    end
  end

  it_behaves_like 'an offensive factory call', ''
  it_behaves_like 'an offensive factory call', 'FactoryBot.'
end
