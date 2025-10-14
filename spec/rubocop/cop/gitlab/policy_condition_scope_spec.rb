# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'
require_relative '../../../../rubocop/cop/gitlab/policy_condition_scope'

RSpec.describe RuboCop::Cop::Gitlab::PolicyConditionScope, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  shared_examples 'scope mismatch' do |scope, ivars, disallowed|
    it 'flags disallowed references' do
      expect_offense(<<~RUBY, scope: scope.inspect, ivars: ivars, disallowed: disallowed)
      condition(:example, scope: %{scope}) do
                                 ^{scope} Scope `#{scope}` uses disallowed references: `%{disallowed}`. See https://docs.gitlab.com/development/policies/#scope
         %{ivars}
      end
      RUBY
    end
  end

  shared_examples 'scope match' do |scope, ivars|
    it 'does not flag any offenses' do
      expect_no_offenses(<<~RUBY)
        condition(:example, scope: #{scope.inspect}) do
          #{ivars}
        end
      RUBY
    end
  end

  where(:scope, :ivars, :example_type, :disallowed) do
    :global           | ''                                  | 'scope match'    | nil
    :global           | 'some_helper?'                      | 'scope match'    | nil
    :global           | 'user.admin?'                       | 'scope mismatch' | 'user'
    :global           | '@user.admin?'                      | 'scope mismatch' | '@user'
    :global           | '@user == @subject'                 | 'scope mismatch' | '@user, @subject'
    :user             | '@user.admin?'                      | 'scope match'    | nil
    :user             | 'user.blocked?'                     | 'scope match'    | nil
    :user             | '@subject.closed?'                  | 'scope mismatch' | '@subject'
    :user             | '@unrelated'                        | 'scope mismatch' | '@unrelated'
    :user             | '@user.thing_is_enabled(subject)'   | 'scope mismatch' | 'subject'
    :user             | '@user.thing_is_enabled(@subject)'  | 'scope mismatch' | '@subject'
    :user             | '@subject.thing_is_enabled(user)'   | 'scope mismatch' | '@subject'
    :subject          | '@subject.closed?'                  | 'scope match'    | nil
    :subject          | 'subject.banned?'                   | 'scope match'    | nil
    :subject          | '@user.blocked?'                    | 'scope mismatch' | '@user'
    :subject          | '@unrelated'                        | 'scope mismatch' | '@unrelated'
    :subject          | '@subject.thing_is_enabled(user)'   | 'scope mismatch' | 'user'
    :subject          | '@subject.thing_is_enabled(@user)'  | 'scope mismatch' | '@user'
    :subject          | '@user.thing_is_enabled(subject)'   | 'scope mismatch' | '@user'
    nil               | '@subject == @user'                 | 'scope match'    | nil
    nil               | 'subject && user'                   | 'scope match'    | nil
    nil               | 'some_helper?'                      | 'scope match'    | nil
    nil               | '@unrelated'                        | 'scope match'    | nil
    :subject          | 'some_helper'                       | 'scope match'    | nil
    :user             | 'some_helper'                       | 'scope match'    | nil
  end

  with_them do
    it_behaves_like params[:example_type], params[:scope], params[:ivars], params[:disallowed]
  end

  context 'when using alias_method' do
    it 'does not register offense for subject alias in subject scope' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          alias_method :project, :subject

          condition(:visible, scope: :subject) do
            project.visible?
          end
        end
      RUBY
    end

    it 'registers offense for subject alias used in user scope' do
      expect_offense(<<~RUBY)
        class ExamplePolicy
          alias_method :project, :subject

          condition(:visible, scope: :user) do
                                     ^^^^^ Scope `user` uses disallowed references: `project`. See https://docs.gitlab.com/development/policies/#scope
            project.visible?
          end
        end
      RUBY
    end
  end

  context 'when using def to alias @subject' do
    it 'does not register offense when alias used in subject scope' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy

          condition(:visible, scope: :subject) do
            project.visible?
          end

          def project
            @subject
          end
        end
      RUBY
    end

    it 'registers offense when alias used in wrong scope' do
      expect_offense(<<~RUBY)
        class ExamplePolicy

          condition(:visible, scope: :user) do
                                     ^^^^^ Scope `user` uses disallowed references: `project`. See https://docs.gitlab.com/development/policies/#scope
            project.visible?
          end

        def project
            @subject
          end
        end
      RUBY
    end
  end

  context 'when method uses only @subject' do
    it 'adds method as subject alias and allows in subject scope' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy

          condition(:visible, scope: :subject) do
            subject_container.visible?
          end

          def subject_container
            @subject.project
          end
        end
      RUBY
    end
  end

  context 'when method uses both @subject and @user' do
    it 'does not add alias and raises offense in any scope' do
      expect_offense(<<~RUBY)
        class ExamplePolicy

          condition(:visible, scope: :subject) do
                                     ^^^^^^^^ Scope `subject` uses disallowed references: `subject_container`. See https://docs.gitlab.com/development/policies/#scope
            subject_container.visible?
          end

          def subject_container
            @subject.project || @user
          end
        end
      RUBY
    end
  end

  context 'when method uses only @user' do
    it 'adds method as user alias and allows in user scope' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy

          condition(:logged_in, scope: :user) do
            current_user.admin?
          end

          def current_user
            @user
          end
        end
      RUBY
    end
  end

  context 'when handling safe predicates and methods used in control flow conditions' do
    it 'ignores method in if condition and allows safe predicate' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          condition(:example, scope: :subject) do
            if group_issue?
              term?
            elsif foo?
              false
            end
          end

          def term?
            true
          end
        end
      RUBY
    end

    it 'ignores method in unless condition and allows safe predicate' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          condition(:example, scope: :subject) do
            unless external_group?
              term?
            end
          end

          def term?
            false
          end
        end
      RUBY
    end

    it 'flags only unsafe method not used in control flow' do
      expect_offense(<<~RUBY)
        class ExamplePolicy
          condition(:example, scope: :subject) do
                                     ^^^^^^^^ Scope `subject` uses disallowed references: `current_user`. See https://docs.gitlab.com/development/policies/#scope

            if group_issue?
              current_user
            end
          end

          def current_user
            @user
          end
        end
      RUBY
    end
  end

  context 'when alias is defined in parent class' do
    let(:parent_source) do
      <<~RUBY
        class BasePolicy
          alias_method :project, :subject
          def namespace
            @subject
          end
        end
      RUBY
    end

    let(:parent_path) { 'app/policies/base_policy.rb' }

    before do
      described_class.clear_cache

      parent_processed_source = RuboCop::ProcessedSource.new(
        parent_source,
        RUBY_VERSION.to_f,
        parent_path
      )

      allow(Dir).to receive(:pwd).and_return('/project')
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/project/#{parent_path}").and_return(true)
      allow(RuboCop::ProcessedSource).to receive(:from_file)
        .with("/project/#{parent_path}", RUBY_VERSION.to_f)
        .and_return(parent_processed_source)
    end

    it 'respects subject alias from parent class' do
      expect_no_offenses(<<~RUBY)
        class IssuePolicy < BasePolicy
          condition(:visible, scope: :subject) { namespace.visible? }
          condition(:visible, scope: :subject) { project.visible?   }
        end
      RUBY
    end
  end

  context 'when EE policy uses CE alias for @subject' do
    let(:ce_source) do
      <<~RUBY
        class FooPolicy < BasePolicy
          def project
            @subject
          end
        end
      RUBY
    end

    let(:ce_path) { '/project/app/policies/foo_policy.rb' }
    let(:ee_path) { '/project/ee/app/policies/foo_policy.rb' }

    before do
      described_class.clear_cache

      ce_processed_source = RuboCop::ProcessedSource.new(
        ce_source,
        RUBY_VERSION.to_f,
        ce_path
      )

      allow(Dir).to receive(:pwd).and_return('/project')
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(ce_path).and_return(true)
      allow(RuboCop::ProcessedSource).to receive(:from_file)
        .with(ce_path, RUBY_VERSION.to_f)
        .and_return(ce_processed_source)
    end

    it 'does not register offense when using CE-defined alias in EE file' do
      expect_no_offenses(<<~RUBY, ee_path)
        module EE
          module FooPolicy
            condition(:visible, scope: :subject) do
              project.visible?
            end
          end
        end
      RUBY
    end

    it 'registers an offense for disallowed reference' do
      expect_offense(<<~RUBY, ee_path)
        module EE
          module SomeModule
            module FooPolicy
              condition(:visible, scope: :subject) do
                                         ^^^^^^^^ Scope `subject` uses disallowed references: `other`. See https://docs.gitlab.com/development/policies/#scope
                other.visible?
              end
            end
          end
        end
      RUBY
    end
  end

  context 'when methods with arguments are used' do
    it 'does not flag methods with arguments as disallowed references' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          condition(:has_permission, scope: :user) do
            @user.admin? && custom_role_ability(:manage_project)
          end
        end
      RUBY
    end

    it 'still flags instance variables passed as arguments' do
      expect_offense(<<~RUBY)
        class ExamplePolicy
          condition(:has_permission, scope: :user) do
                                            ^^^^^ Scope `user` uses disallowed references: `@subject`. See https://docs.gitlab.com/development/policies/#scope
            @user.admin? && custom_role_ability(@subject)
          end
        end
      RUBY
    end
  end
end
