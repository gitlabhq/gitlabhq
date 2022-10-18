# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../../rubocop/cop/rspec/factory_bot/avoid_create'

RSpec.describe RuboCop::Cop::RSpec::FactoryBot::AvoidCreate do
  shared_examples 'an offensive factory call' do |namespace|
    %i[create create_list].each do |forbidden_method|
      namespaced_forbidden_method = "#{namespace}#{forbidden_method}(:user)"

      it "registers an offense for #{namespaced_forbidden_method}" do
        expect_offense(<<-RUBY)
        describe 'foo' do
          let(:user) { #{namespaced_forbidden_method} }
                       #{'^' * namespaced_forbidden_method.size} Prefer using `build_stubbed` or similar over `#{forbidden_method}`. See https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#optimize-factory-usage
        end
        RUBY
      end
    end
  end

  it_behaves_like 'an offensive factory call', ''
  it_behaves_like 'an offensive factory call', 'FactoryBot.'
end
