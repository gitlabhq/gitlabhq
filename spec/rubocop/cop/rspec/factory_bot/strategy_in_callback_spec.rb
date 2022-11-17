# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../../rubocop/cop/rspec/factory_bot/strategy_in_callback'

RSpec.describe RuboCop::Cop::RSpec::FactoryBot::StrategyInCallback do
  shared_examples 'an offensive factory call' do |namespace|
    described_class::FORBIDDEN_METHODS.each do |forbidden_method|
      namespaced_forbidden_method = "#{namespace}#{forbidden_method}(:ci_job_artifact, :archive)"

      it "registers an offence for multiple #{namespaced_forbidden_method} calls" do
        expect_offense(<<-RUBY)
        FactoryBot.define do
          factory :ci_build, class: 'Ci::Build', parent: :ci_processable do
            trait :artifacts do
              before(:create) do
                #{namespaced_forbidden_method}
                #{'^' * namespaced_forbidden_method.size} Prefer inline `association` over `#{forbidden_method}`. See https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#factories
              end

              after(:create) do |build|
                #{namespaced_forbidden_method}
                #{'^' * namespaced_forbidden_method.size} Prefer inline `association` over `#{forbidden_method}`. See https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#factories
                #{namespaced_forbidden_method}
                #{'^' * namespaced_forbidden_method.size} Prefer inline `association` over `#{forbidden_method}`. See https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#factories
              end
            end
          end
        end
        RUBY
      end

      it "registers an offense for #{namespaced_forbidden_method} when is a send node" do
        expect_offense(<<-RUBY)
        FactoryBot.define do
          factory :ci_build, class: 'Ci::Build', parent: :ci_processable do
            trait :artifacts do
              after(:create) do |build|
                #{namespaced_forbidden_method}
                #{'^' * namespaced_forbidden_method.size} Prefer inline `association` over `#{forbidden_method}`. See https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#factories
              end
            end
          end
        end
        RUBY
      end

      it "registers an offense for #{namespaced_forbidden_method} when is assigned" do
        expect_offense(<<-RUBY)
        FactoryBot.define do
          factory :ci_build, class: 'Ci::Build', parent: :ci_processable do
            trait :artifacts do
              after(:create) do |build|
                ci_build = #{namespaced_forbidden_method}
                           #{'^' * namespaced_forbidden_method.size} Prefer inline `association` over `#{forbidden_method}`. See https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#factories

                ci_build
              end
            end
          end
        end
        RUBY
      end
    end
  end

  it_behaves_like 'an offensive factory call', ''
  it_behaves_like 'an offensive factory call', 'FactoryBot.'
  it_behaves_like 'an offensive factory call', '::FactoryBot.'
end
