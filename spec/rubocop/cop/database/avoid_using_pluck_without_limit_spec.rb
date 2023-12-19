# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/database/avoid_using_pluck_without_limit'

RSpec.describe RuboCop::Cop::Database::AvoidUsingPluckWithoutLimit, feature_category: :database do
  context 'when using pluck without a limit' do
    it 'flags the use of pluck as a model scope' do
      expect_offense(<<~RUBY)
        class MyModel < ApplicationRecord
          scope :all_users, -> { where(user_id: User.pluck(:id)) }
                                                     ^^^^^ #{described_class::MSG}
        end
      RUBY
    end

    it 'flags the use of pluck as a regular method' do
      expect_offense(<<~RUBY)
        class MyModel < ApplicationRecord
          def all
           self.pluck(:id)
                ^^^^^ #{described_class::MSG}
          end
        end
      RUBY
    end

    it 'flags the use of pluck inside where' do
      expect_offense(<<~RUBY)
        class MyModel < ApplicationRecord
          def all_projects
           Project.where(id: self.pluck(:id))
                                  ^^^^^ #{described_class::MSG}
          end
        end
      RUBY
    end

    it 'flags the use of pluck inside a model class method' do
      allow(cop).to receive(:in_model?).and_return(true)

      expect_offense(<<~RUBY)
        class MyClass < Model
          def all_users
           User.where(id: self.pluck(:id))
                               ^^^^^ #{described_class::MSG}
          end
        end
      RUBY
    end

    it 'flags the use of pluck inside a finder' do
      allow(cop).to receive(:in_finder?).and_return(true)

      expect_offense(<<~RUBY)
        class MyFinder
          def find(path)
           Project.where(path: path).pluck(:id)
                                     ^^^^^ #{described_class::MSG}
          end
        end
      RUBY
    end

    it 'flags the use of pluck inside a service' do
      allow(cop).to receive(:in_service_class?).and_return(true)

      expect_offense(<<~RUBY)
        class MyService
          def delete_all(project)
           delete(project.for_scan_result_policy_read(scan_result_policy_reads.pluck(:id)))
                                                                               ^^^^^ #{described_class::MSG}
          end
        end
      RUBY
    end
  end

  context 'when using pluck with a limit' do
    it 'does not flags the use of pluck as a model scope' do
      expect_no_offenses(<<~RUBY)
        class MyModel < ApplicationRecord
          scope :all_users, ->(limit) { where(user_id: User.limit(limit).pluck(:id)) }
        end
      RUBY
    end

    it 'does not flags the use of pluck as a regular method' do
      expect_no_offenses(<<~RUBY)
        class MyModel < ApplicationRecord
          def all(limit)
            self.limit(limit).pluck(:id)
          end
        end
      RUBY
    end

    it 'does not flags the use of pluck inside where' do
      expect_no_offenses(<<~RUBY)
        class MyModel < ApplicationRecord
          def all_projects(limit)
            Project.where(id: self.limit(limit).pluck(:id))
          end
        end
      RUBY
    end

    it 'does not flags the use of pluck inside a model class method' do
      allow(cop).to receive(:in_model?).and_return(true)

      expect_no_offenses(<<~RUBY)
        class MyClass < Model
          def all_users
           User.where(id: self.limit(100).pluck(:id))
          end
        end
      RUBY
    end

    it 'does not flags the use of pluck inside a finder' do
      allow(cop).to receive(:in_finder?).and_return(true)

      expect_no_offenses(<<~RUBY)
        class MyFinder
          def find(path)
           Project.where(path: path).limit(100).pluck(:id)
          end
        end
      RUBY
    end

    it 'flags the use of pluck inside a service' do
      allow(cop).to receive(:in_service_class?).and_return(true)

      expect_no_offenses(<<~RUBY)
        class MyService
          def delete_all(project)
           delete(project.for_scan_result_policy_read(scan_result_policy_reads.limit(100).pluck(:id)))
          end
        end
      RUBY
    end
  end
end
