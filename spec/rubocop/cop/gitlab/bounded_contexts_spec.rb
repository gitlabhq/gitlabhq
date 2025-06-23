# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/bounded_contexts'

RSpec.describe RuboCop::Cop::Gitlab::BoundedContexts, feature_category: :tooling do
  it 'flags an offense for an empty non bounded context module' do
    expect_offense(<<~RUBY)
      module NotABoundedContext
             ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
      end
    RUBY
  end

  it 'flags an offense for a non bounded context module which contains a class' do
    expect_offense(<<~RUBY)
      module NotABoundedContext
             ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
        class NotABoundedContextClass
        end
      end
    RUBY
  end

  it 'flags an offense for a non bounded context module which contains a class (compact version)' do
    expect_offense(<<~RUBY)
      class NotABoundedContext::SomeClass
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Class `NotABoundedContext::SomeClass` is not within a valid bounded context module. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
      end
    RUBY
  end

  it 'flags an offense for a non bounded context module which contains a module' do
    expect_offense(<<~RUBY)
      module NotABoundedContext
             ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
        module NotABoundedContextEither
        end
      end
    RUBY
  end

  it 'flags an offense for a class which is not within a module' do
    expect_offense(<<~RUBY)
      class AClassNotInAModule
            ^^^^^^^^^^^^^^^^^^ Class `AClassNotInAModule` is not within a valid bounded context module. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
      end
    RUBY
  end

  it 'does not flag an offense for a bounded context module' do
    expect_no_offenses(<<~RUBY)
      module RemoteDevelopment
      end
    RUBY
  end

  it 'does not flag an offense for a class which IS within a bounded context' do
    expect_no_offenses(<<~RUBY)
      module RemoteDevelopment
        class ABoundedContextClass
        end
      end
    RUBY
  end

  it 'does not flag an offense for a module which IS within a bounded context' do
    expect_no_offenses(<<~RUBY)
      module RemoteDevelopment
        module SomeModule
        end
      end
    RUBY
  end

  it 'does not flag an offense for a class which is nested more than one module deep in a bounded context' do
    expect_no_offenses(<<~RUBY)
      module RemoteDevelopment
        module Workspaces
          module Create
            class Authorizer
            end
          end
        end
      end
    RUBY
  end

  it 'does not flag an offense for a platform module' do
    expect_no_offenses(<<~RUBY)
      module Gitlab
      end
    RUBY
  end

  it 'does not flag an offense for a class inside a platform module' do
    expect_no_offenses(<<~RUBY)
      module Gitlab
        class SomeUtils
        end
      end
    RUBY
  end

  describe 'EE extensions' do
    it 'does not flag an offense for an EE module inside a platform module' do
      expect_no_offenses(<<~RUBY)
        module EE
          module Gitlab
            class SomeClass
            end
          end
        end
      RUBY
    end

    it 'does not flag an offense for an EE module inside a bounded context namespace' do
      expect_no_offenses(<<~RUBY)
        module EE
          module RemoteDevelopment
            class SomeClass
            end
          end
        end
      RUBY
    end

    it 'does not flag an offense for an EE module inside a bounded context namespace (compact version)' do
      expect_no_offenses(<<~RUBY)
        class EE::RemoteDevelopment::SomeClass
        end
      RUBY
    end

    it 'flags an offense inside an EE module' do
      expect_offense(<<~RUBY)
        module EE
          module NotABoundedContext
                 ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
            class SomeClass
            end
          end
        end
      RUBY
    end

    it 'flags an offense inside an EE module (compact version)' do
      expect_offense(<<~RUBY)
        module EE::NotABoundedContext
               ^^^^^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
          class SomeClass
          end
        end
      RUBY
    end
  end

  describe 'GraphQL code' do
    %w[
      Mutations
      Types
      Resolvers
      Subscriptions
    ].each do |clazz|
      it "flags an offense for a #{clazz.downcase.singularize} not in a bounded context" do
        expect_offense(<<~RUBY)
        module #{clazz}
          module NotABoundedContext
                 ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
          end
        end
        RUBY
      end

      it "does not flag an offense for a #{clazz.downcase.singularize} in a bounded context" do
        expect_no_offenses(<<~RUBY)
        module #{clazz}
          module RemoteDevelopment
          end
        end
        RUBY
      end

      it "does not flag an offense for a #{clazz.downcase.singularize} in a bounded context inside an EE extension" do
        expect_no_offenses(<<~RUBY)
        module EE
          module #{clazz}
            module RemoteDevelopment
            end
          end
        end
        RUBY
      end

      it "flags an offense for a #{clazz.downcase.singularize} not in a bounded context inside an EE extension" do
        expect_offense(<<~RUBY)
          module EE
            module #{clazz}
              module NotABoundedContext
                     ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
              end
            end
          end
        RUBY
      end
    end

    it 'flags an offense for a permission type not in a bounded context' do
      expect_offense(<<~RUBY)
        module Types
          module PermissionTypes
            module NotABoundedContext
                   ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
            end
          end
        end
      RUBY
    end

    it 'flags an offense for a permission type not in a bounded context (compact)' do
      expect_offense(<<~RUBY)
        module Types::PermissionTypes::NotABoundedContext
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
        end
      RUBY
    end

    it 'does not flag an offense for a permission type in a bounded context' do
      expect_no_offenses(<<~RUBY)
        module Types
          module PermissionTypes
            module RemoteDevelopment
            end
          end
        end
      RUBY
    end

    it 'does not flag an offense for a permission type in a bounded context inside an EE extension' do
      expect_no_offenses(<<~RUBY)
      module EE
        module Types
          module PermissionTypes
            module RemoteDevelopment
            end
          end
        end
      end
      RUBY
    end

    it 'flags an offense for a permission type not in a bounded context inside an EE extension' do
      expect_offense(<<~RUBY)
      module EE
        module Types
          module PermissionTypes
            module NotABoundedContext
                   ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
            end
          end
        end
      end
      RUBY
    end
  end
end
