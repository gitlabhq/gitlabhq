# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require_relative '../../../../../rubocop/cop/rspec/factory_bot/inline_association'

RSpec.describe RuboCop::Cop::RSpec::FactoryBot::InlineAssociation do
  subject(:cop) { described_class.new }

  shared_examples 'offense' do |code_snippet, autocorrected|
    # We allow `create` or `FactoryBot.create` or `::FactoryBot.create`
    let(:type) { code_snippet[/^(?:::)?(?:FactoryBot\.)?(\w+)/, 1] }
    let(:offense_marker) { '^' * code_snippet.size }
    let(:offense_msg) { msg(type) }
    let(:offense) { "#{offense_marker} #{offense_msg}" }
    let(:source) do
      <<~RUBY
        FactoryBot.define do
          factory :project do
            attribute { #{code_snippet} }
                        #{offense}
          end
        end
      RUBY
    end

    let(:corrected_source) do
      <<~RUBY
        FactoryBot.define do
          factory :project do
            attribute { #{autocorrected} }
          end
        end
      RUBY
    end

    it 'registers an offense and corrects', :aggregate_failures do
      expect_offense(source)

      expect_correction(corrected_source)
    end
  end

  shared_examples 'no offense' do |code_snippet|
    first_line = code_snippet.lines.first.chomp

    context "for `#{first_line}`" do
      it 'does not register any offenses' do
        expect_no_offenses <<~RUBY
          FactoryBot.define do
            factory :project do
              #{code_snippet}
            end
          end
        RUBY
      end
    end
  end

  context 'offenses' do
    using RSpec::Parameterized::TableSyntax

    where(:code_snippet, :autocorrected) do
      # create
      'create(:user)'              | 'association(:user)'
      'FactoryBot.create(:user)'   | 'association(:user)'
      '::FactoryBot.create(:user)' | 'association(:user)'
      'create(:user, :admin)'      | 'association(:user, :admin)'
      'create(:user, name: "any")' | 'association(:user, name: "any")'
      # build
      'build(:user)'               | 'association(:user)'
      'FactoryBot.build(:user)'    | 'association(:user)'
      '::FactoryBot.build(:user)'  | 'association(:user)'
      'build(:user, :admin)'       | 'association(:user, :admin)'
      'build(:user, name: "any")'  | 'association(:user, name: "any")'
    end

    with_them do
      include_examples 'offense', params[:code_snippet], params[:autocorrected]
    end

    it 'recognizes `add_attribute`' do
      expect_offense <<~RUBY
        FactoryBot.define do
          factory :project, class: 'Project' do
            add_attribute(:method) { create(:user) }
                                     ^^^^^^^^^^^^^ #{msg(:create)}
          end
        end
      RUBY
    end

    it 'recognizes `transient` attributes' do
      expect_offense <<~RUBY
        FactoryBot.define do
          factory :project, class: 'Project' do
            transient do
              creator { create(:user) }
                        ^^^^^^^^^^^^^ #{msg(:create)}
            end
          end
        end
      RUBY
    end
  end

  context 'no offenses' do
    include_examples 'no offense', 'association(:user)'
    include_examples 'no offense', 'association(:user, :admin)'
    include_examples 'no offense', 'association(:user, name: "any")'

    include_examples 'no offense', <<~RUBY
      after(:build) do |object|
        object.user = create(:user)
      end
    RUBY

    include_examples 'no offense', <<~RUBY
      initialize_with do
        create(:user)
      end
    RUBY

    include_examples 'no offense', <<~RUBY
      user_id { create(:user).id }
    RUBY
  end

  def msg(type)
    format(described_class::MSG, type: type)
  end
end
