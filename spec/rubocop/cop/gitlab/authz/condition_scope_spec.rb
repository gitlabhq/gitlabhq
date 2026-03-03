# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'
require_relative '../../../../../rubocop/cop/gitlab/authz/condition_scope'

RSpec.describe RuboCop::Cop::Gitlab::Authz::ConditionScope, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  before do
    described_class.clear_cache
  end

  # --- Inline scope: condition(:name, scope: :X) ---

  context 'with inline scope argument' do
    shared_examples 'scope mismatch' do |scope, ivars, disallowed|
      it 'flags disallowed references' do
        cache_desc = { subject: 'per-subject', user: 'per-user', global: 'globally' }[scope]
        expect_offense(<<~RUBY, scope: scope.inspect, ivars: ivars, disallowed: disallowed)
        condition(:example, scope: %{scope}) do
                                   ^{scope} Scope `#{scope}` caches #{cache_desc} but `%{disallowed}` was referenced. This causes cache bugs. Remove the scope or the disallowed references. See https://docs.gitlab.com/development/policies/#scope
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
      :global  | ''                                 | 'scope match'    | nil
      :global  | 'some_helper?'                     | 'scope match'    | nil
      :global  | 'user.admin?'                      | 'scope mismatch' | 'user'
      :global  | '@user.admin?'                     | 'scope mismatch' | '@user'
      :global  | '@user == @subject'                | 'scope mismatch' | '@user, @subject'
      :user    | '@user.admin?'                     | 'scope match'    | nil
      :user    | 'user.blocked?'                    | 'scope match'    | nil
      :user    | '@subject.closed?'                 | 'scope mismatch' | '@subject'
      :user    | '@unrelated'                       | 'scope mismatch' | '@unrelated'
      :user    | '@user.thing_is_enabled(subject)'  | 'scope mismatch' | 'subject'
      :user    | '@user.thing_is_enabled(@subject)' | 'scope mismatch' | '@subject'
      :subject | '@subject.closed?'                 | 'scope match'    | nil
      :subject | 'subject.banned?'                  | 'scope match'    | nil
      :subject | '@user.blocked?'                   | 'scope mismatch' | '@user'
      :subject | '@unrelated'                       | 'scope mismatch' | '@unrelated'
      :subject | '@subject.thing_is_enabled(user)'  | 'scope mismatch' | 'user'
      :subject | '@subject.thing_is_enabled(@user)' | 'scope mismatch' | '@user'
      nil      | '@subject == @user'                | 'scope match'    | nil
      nil      | 'some_helper?'                     | 'scope match'    | nil
      nil      | '@unrelated'                       | 'scope match'    | nil
      :subject | 'some_helper'                      | 'scope match'    | nil
      :user    | 'some_helper'                      | 'scope match'    | nil
    end

    with_them do
      it_behaves_like params[:example_type], params[:scope], params[:ivars], params[:disallowed]
    end
  end

  # --- with_scope :X ---

  context 'with with_scope' do
    it 'flags disallowed references with scope: :subject referencing @user' do
      expect_offense(<<~RUBY)
        class ExamplePolicy
          with_scope :subject
          ^^^^^^^^^^^^^^^^^^^ Scope `subject` caches per-subject but `@user` was referenced. This causes cache bugs. Remove the scope or the disallowed references. See https://docs.gitlab.com/development/policies/#scope
          condition(:forking_allowed) do
            @subject.feature_available?(:forking, @user)
          end
        end
      RUBY
    end

    it 'flags disallowed references with scope: :user referencing @subject' do
      expect_offense(<<~RUBY)
        class ExamplePolicy
          with_scope :user
          ^^^^^^^^^^^^^^^^ Scope `user` caches per-user but `@subject` was referenced. This causes cache bugs. Remove the scope or the disallowed references. See https://docs.gitlab.com/development/policies/#scope
          condition(:visible) do
            @subject.visible?
          end
        end
      RUBY
    end

    it 'flags disallowed references with scope: :global referencing @user' do
      expect_offense(<<~RUBY)
        class ExamplePolicy
          with_scope :global
          ^^^^^^^^^^^^^^^^^^ Scope `global` caches globally but `@user` was referenced. This causes cache bugs. Remove the scope or the disallowed references. See https://docs.gitlab.com/development/policies/#scope
          condition(:locked_rules) do
            !@user.can_admin_all_resources? && License.feature_available?(:feature)
          end
        end
      RUBY
    end

    it 'does not flag valid scope: :subject condition' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          with_scope :subject
          condition(:closed) { @subject.closed? }
        end
      RUBY
    end

    it 'does not flag valid scope: :user condition' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          with_scope :user
          condition(:admin) { @user.admin? }
        end
      RUBY
    end

    it 'does not flag valid scope: :global condition' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          with_scope :global
          condition(:mirror_available) do
            ::Gitlab::CurrentSettings.mirror_available
          end
        end
      RUBY
    end

    it 'applies with_scope only to the immediately following condition' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          with_scope :subject
          condition(:closed) { @subject.closed? }

          condition(:admin) { @user.admin? }
        end
      RUBY
    end

    it 'handles multiple consecutive with_scope declarations' do
      expect_offense(<<~RUBY)
        class ExamplePolicy
          with_scope :subject
          condition(:closed) { @subject.closed? }

          with_scope :subject
          ^^^^^^^^^^^^^^^^^^^ Scope `subject` caches per-subject but `@user` was referenced. This causes cache bugs. Remove the scope or the disallowed references. See https://docs.gitlab.com/development/policies/#scope
          condition(:forking) do
            @subject.feature_available?(:forking, @user)
          end
        end
      RUBY
    end
  end

  # --- with_options scope: :X ---

  context 'with with_options' do
    it 'flags disallowed references with with_options scope: :subject referencing @user' do
      expect_offense(<<~RUBY)
        class ExamplePolicy
          with_options scope: :subject, score: 0
                              ^^^^^^^^ Scope `subject` caches per-subject but `@user` was referenced. This causes cache bugs. Remove the scope or the disallowed references. See https://docs.gitlab.com/development/policies/#scope
          condition(:has_key) { @user.keys.any? }
        end
      RUBY
    end

    it 'flags disallowed references with with_options scope: :user referencing @subject' do
      expect_offense(<<~RUBY)
        class ExamplePolicy
          with_options scope: :user, score: 0
                              ^^^^^ Scope `user` caches per-user but `@subject` was referenced. This causes cache bugs. Remove the scope or the disallowed references. See https://docs.gitlab.com/development/policies/#scope
          condition(:closed) { @subject.closed? }
        end
      RUBY
    end

    it 'does not flag valid with_options scope: :user condition' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          with_options scope: :user, score: 0
          condition(:blocked) { @user&.blocked? }
        end
      RUBY
    end

    it 'does not flag valid with_options scope: :subject condition' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          with_options scope: :subject, score: 0
          condition(:private) { @subject.private? }
        end
      RUBY
    end

    it 'applies with_options only to the immediately following condition' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          with_options scope: :subject, score: 0
          condition(:private) { @subject.private? }

          condition(:admin) { @user.admin? }
        end
      RUBY
    end
  end

  # --- Alias handling ---

  context 'when using alias_method' do
    it 'does not register offense for subject alias in subject scope with with_scope' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          alias_method :project, :subject

          with_scope :subject
          condition(:visible) { project.visible? }
        end
      RUBY
    end

    it 'registers offense for subject alias used in user scope with with_scope' do
      expect_offense(<<~RUBY)
        class ExamplePolicy
          alias_method :project, :subject

          with_scope :user
          ^^^^^^^^^^^^^^^^ Scope `user` caches per-user but `project` was referenced. This causes cache bugs. Remove the scope or the disallowed references. See https://docs.gitlab.com/development/policies/#scope
          condition(:visible) do
            project.visible?
          end
        end
      RUBY
    end

    it 'does not register offense for user alias in user scope with with_options' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          alias_method :current_user, :user

          with_options scope: :user, score: 0
          condition(:admin) { current_user.admin? }
        end
      RUBY
    end
  end

  context 'when using def to create aliases' do
    it 'does not register offense for subject alias in with_scope :subject' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          with_scope :subject
          condition(:visible) { project.visible? }

          def project
            @subject
          end
        end
      RUBY
    end

    it 'registers offense when alias used in wrong scope with with_scope' do
      expect_offense(<<~RUBY)
        class ExamplePolicy
          with_scope :user
          ^^^^^^^^^^^^^^^^ Scope `user` caches per-user but `project` was referenced. This causes cache bugs. Remove the scope or the disallowed references. See https://docs.gitlab.com/development/policies/#scope
          condition(:visible) do
            project.visible?
          end

          def project
            @subject
          end
        end
      RUBY
    end
  end

  # --- Safe predicates ---

  context 'with safe predicates in control flow' do
    it 'ignores method in if condition and allows safe predicate' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          with_scope :subject
          condition(:example) do
            if group_issue?
              term?
            end
          end

          def term?
            true
          end
        end
      RUBY
    end
  end

  # --- Parent class alias resolution ---

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

    it 'respects subject alias from parent class with with_scope' do
      expect_no_offenses(<<~RUBY)
        class IssuePolicy < BasePolicy
          with_scope :subject
          condition(:visible) { namespace.visible? }

          with_scope :subject
          condition(:open) { project.open? }
        end
      RUBY
    end
  end

  # --- Methods with arguments ---

  context 'when methods with arguments are used' do
    it 'does not flag methods with arguments as disallowed references' do
      expect_no_offenses(<<~RUBY)
        class ExamplePolicy
          with_scope :user
          condition(:has_permission) do
            @user.admin? && custom_role_ability(:manage_project)
          end
        end
      RUBY
    end

    it 'still flags instance variables passed as arguments' do
      expect_offense(<<~RUBY)
        class ExamplePolicy
          with_scope :user
          ^^^^^^^^^^^^^^^^ Scope `user` caches per-user but `@subject` was referenced. This causes cache bugs. Remove the scope or the disallowed references. See https://docs.gitlab.com/development/policies/#scope
          condition(:has_permission) do
            @user.admin? && custom_role_ability(@subject)
          end
        end
      RUBY
    end
  end

  # --- Module context (EE policies) ---

  context 'with a module context' do
    it 'handles with_scope inside modules' do
      expect_offense(<<~RUBY)
        module EE
          module ProjectPolicy
            with_scope :global
            ^^^^^^^^^^^^^^^^^^ Scope `global` caches globally but `@user` was referenced. This causes cache bugs. Remove the scope or the disallowed references. See https://docs.gitlab.com/development/policies/#scope
            condition(:locked_rules) do
              !@user.can_admin_all_resources?
            end
          end
        end
      RUBY
    end

    it 'does not flag valid conditions inside modules' do
      expect_no_offenses(<<~RUBY)
        module EE
          module ProjectPolicy
            with_scope :subject
            condition(:feature_available) { @subject.feature_available?(:feature) }
          end
        end
      RUBY
    end
  end

  # --- prepended do blocks (EE pattern) ---

  context 'with a prepended block' do
    it 'flags disallowed references inside prepended block' do
      expect_offense(<<~RUBY)
        module EE
          module ProjectPolicy
            extend ActiveSupport::Concern

            prepended do
              with_scope :global
              ^^^^^^^^^^^^^^^^^^ Scope `global` caches globally but `@user` was referenced. This causes cache bugs. Remove the scope or the disallowed references. See https://docs.gitlab.com/development/policies/#scope
              condition(:locked_rules) do
                !@user.can_admin_all_resources?
              end
            end
          end
        end
      RUBY
    end

    it 'does not flag valid conditions inside prepended block' do
      expect_no_offenses(<<~RUBY)
        module EE
          module ProjectPolicy
            extend ActiveSupport::Concern

            prepended do
              with_scope :subject
              condition(:feature_available) { @subject.feature_available?(:feature) }
            end
          end
        end
      RUBY
    end
  end
end
