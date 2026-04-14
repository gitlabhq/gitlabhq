# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/database/avoid_unpartitioned_ci_relations'

RSpec.describe RuboCop::Cop::Database::AvoidUnpartitionedCiRelations, feature_category: :database do
  shared_examples 'flags unpartitioned relation' do |relation|
    it 'registers an offense for project instance variable' do
      expect_offense(<<~RUBY, relation: relation)
        class MyService
          def execute
            @project.#{relation}
                     ^{relation} Avoid calling `#{relation}` [...]
          end
        end
      RUBY
    end

    it 'registers an offense for project local variable' do
      expect_offense(<<~RUBY, relation: relation)
        class MyService
          def execute
            project.#{relation}
                    ^{relation} Avoid calling `#{relation}` [...]
          end
        end
      RUBY
    end

    it 'registers an offense when chaining additional methods' do
      expect_offense(<<~RUBY, relation: relation)
        class MyService
          def execute
            project.#{relation}.where(status: :failed)
                    ^{relation} Avoid calling `#{relation}` [...]
          end
        end
      RUBY
    end

    it 'registers an offense for find_project method' do
      expect_offense(<<~RUBY, relation: relation)
        class MyService
          def execute
            find_project.#{relation}
                         ^{relation} Avoid calling `#{relation}` [...]
          end
        end
      RUBY
    end

    it 'registers an offense for target_project method' do
      expect_offense(<<~RUBY, relation: relation)
        class MyService
          def execute
            target_project.#{relation}
                           ^{relation} Avoid calling `#{relation}` [...]
          end
        end
      RUBY
    end

    it 'registers an offense for safe navigation operator' do
      expect_offense(<<~RUBY, relation: relation)
        class MyService
          def execute
            project&.#{relation}
                     ^{relation} Avoid calling `#{relation}` [...]
          end
        end
      RUBY
    end
  end

  shared_examples 'allows in_partition' do |relation|
    it 'does not register an offense for project instance variable' do
      expect_no_offenses(<<~RUBY)
        class MyService
          def execute
            @project.#{relation}.in_partition(106)
          end
        end
      RUBY
    end

    it 'does not register an offense for project local variable' do
      expect_no_offenses(<<~RUBY)
        class MyService
          def execute
            project.#{relation}.in_partition(106)
          end
        end
      RUBY
    end

    it 'does not register an offense when chaining methods after in_partition' do
      expect_no_offenses(<<~RUBY)
        class MyService
          def execute
            project.#{relation}.in_partition(106).where(status: :failed)
          end
        end
      RUBY
    end

    it 'does not register an offense for find_project with in_partition' do
      expect_no_offenses(<<~RUBY)
        class MyService
          def execute
            find_project.#{relation}.in_partition(106)
          end
        end
      RUBY
    end

    it 'does not register an offense when in_partition is called before other methods' do
      expect_no_offenses(<<~RUBY)
        class MyService
          def execute
            project.#{relation}.in_partition(106).recent.limit(10)
          end
        end
      RUBY
    end

    it 'does not register an offense for safe navigation with in_partition' do
      expect_no_offenses(<<~RUBY)
        class MyService
          def execute
            project&.#{relation}.in_partition(106)
          end
        end
      RUBY
    end
  end

  described_class::PARTITIONED_CI_RELATIONS.each do |relation|
    context "when calling #{relation} without in_partition" do
      it_behaves_like 'flags unpartitioned relation', relation
    end

    context "when calling #{relation} with in_partition" do
      it_behaves_like 'allows in_partition', relation
    end
  end

  context 'when calling non-partitioned relations' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class MyService
          def execute
            project.issues
            project.merge_requests
            project.members
            project.labels
          end
        end
      RUBY
    end
  end

  context 'when calling on non-project receivers' do
    it 'does not register an offense for user' do
      expect_no_offenses(<<~RUBY)
        class MyService
          def execute
            user.all_pipelines
            namespace.builds
          end
        end
      RUBY
    end

    it 'does not register an offense for other objects' do
      expect_no_offenses(<<~RUBY)
        class MyService
          def execute
            pipeline.builds
            ci_pipeline.stages
          end
        end
      RUBY
    end

    it 'does not register an offense for method calls containing "project" but not being projects' do
      expect_no_offenses(<<~RUBY)
        class MyService
          def execute
            project_namespace.all_pipelines
            project_setting.builds
            project_feature.job_artifacts
          end
        end
      RUBY
    end
  end

  context 'when calling on instance variables containing "project"' do
    it 'registers an offense for instance variables with "project" in the name' do
      expect_offense(<<~RUBY)
        class MyService
          def execute
            @my_project.all_pipelines
                        ^^^^^^^^^^^^^ Avoid calling `all_pipelines` [...]
          end
        end
      RUBY
    end

    it 'registers an offense for instance variables ending with "project"' do
      expect_offense(<<~RUBY)
        class MyService
          def execute
            @source_project.builds
                            ^^^^^^ Avoid calling `builds` [...]
          end
        end
      RUBY
    end
  end

  context 'when receiver is nil or missing' do
    it 'does not register an offense for method calls without explicit receiver' do
      expect_no_offenses(<<~RUBY)
        class MyService
          def execute
            all_pipelines
            builds
          end
        end
      RUBY
    end
  end

  context 'when calling on constant receivers' do
    it 'does not register an offense for constant receivers' do
      expect_no_offenses(<<~RUBY)
        class MyService
          def execute
            PROJECT.all_pipelines
            ::Project.builds
          end
        end
      RUBY
    end
  end

  context 'when method chain includes conditional nodes' do
    it 'does not register an offense when in_partition is in a conditional chain' do
      expect_no_offenses(<<~RUBY)
        class MyService
          def execute
            (project.all_pipelines.in_partition(106) if condition)
          end
        end
      RUBY
    end

    it 'does not register an offense when in_partition is in a ternary expression' do
      expect_no_offenses(<<~RUBY)
        class MyService
          def execute
            condition ? project.all_pipelines.in_partition(106) : []
          end
        end
      RUBY
    end
  end
end
