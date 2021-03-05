# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../rubocop/cop/rspec/factories_in_migration_specs'

RSpec.describe RuboCop::Cop::RSpec::FactoriesInMigrationSpecs do
  subject(:cop) { described_class.new }

  shared_examples 'an offensive factory call' do |namespace|
    %i[build build_list create create_list attributes_for].each do |forbidden_method|
      namespaced_forbidden_method = "#{namespace}#{forbidden_method}(:user)"

      it "registers an offense for #{namespaced_forbidden_method}" do
        expect_offense(<<-RUBY)
        describe 'foo' do
          let(:user) { #{namespaced_forbidden_method} }
                       #{'^' * namespaced_forbidden_method.size} Don't use FactoryBot.#{forbidden_method} in migration specs, use `table` instead.
        end
        RUBY
      end
    end
  end

  it_behaves_like 'an offensive factory call', ''
  it_behaves_like 'an offensive factory call', 'FactoryBot.'
end
