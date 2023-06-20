# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../../rubocop/cop/rspec/factory_bot/local_static_assignment'

RSpec.describe RuboCop::Cop::RSpec::FactoryBot::LocalStaticAssignment, feature_category: :tooling do
  shared_examples 'local static assignment' do |block|
    it "flags static local assignment in `#{block}`" do
      expect_offense(<<~RUBY, block: block)
        %{block} do
          age
          name

          random_number = rand(23)
          ^^^^^^^^^^^^^^^^^^^^^^^^ Avoid local static assignemnts in factories which lead to static data definitions.

          random_string = SecureRandom.uuid
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid local static assignemnts in factories which lead to static data definitions.

          project
        end
      RUBY
    end

    it 'does not flag correct use' do
      expect_no_offenses(<<~RUBY)
        #{block} do
          age do
            random_number = rand(23)
            random_number + 1
          end
        end
      RUBY
    end
  end

  it_behaves_like 'local static assignment', 'factory :project'
  it_behaves_like 'local static assignment', 'transient'
  it_behaves_like 'local static assignment', 'trait :closed'

  it 'does not flag local assignments in unrelated blocks' do
    expect_no_offenses(<<~RUBY)
      factory :project do
        sequence(:number) do |n|
          random_number = rand(23)
          random_number * n
        end

        name do
          random_string = SecureRandom.uuid
          random_string + "-name"
        end

        initialize_with do
          random_string = SecureRandom.uuid
          new(name: random_string)
        end
      end
    RUBY
  end
end
