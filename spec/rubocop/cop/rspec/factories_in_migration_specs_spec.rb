require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/rspec/factories_in_migration_specs'

describe RuboCop::Cop::RSpec::FactoriesInMigrationSpecs do
  include CopHelper

  let(:source_file) { 'spec/migrations/foo_spec.rb' }

  subject(:cop) { described_class.new }

  shared_examples 'an offensive factory call' do |namespace|
    %i[build build_list create create_list].each do |forbidden_method|
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

  context 'in a migration spec file' do
    before do
      allow(cop).to receive(:in_migration_spec?).and_return(true)
    end

    it_behaves_like 'an offensive factory call', ''
    it_behaves_like 'an offensive factory call', 'FactoryBot.'
  end

  context 'outside of a migration spec file' do
    it "does not register an offense" do
      expect_no_offenses(<<-RUBY)
        describe 'foo' do
          let(:user) { create(:user) }
        end
      RUBY
    end
  end
end
