# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/bounded_contexts'

RSpec.describe RuboCop::Cop::Gitlab::BoundedContexts, feature_category: :tooling do
  it 'flags an offense for an empty non bounded context module' do
    expect_offense(<<~SOURCE)
      module NotABoundedContext
             ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
      end
    SOURCE
  end

  it 'flags an offense for a non bounded context module which contains a class' do
    expect_offense(<<~SOURCE)
      module NotABoundedContext
             ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
        class NotABoundedContextClass
        end
      end
    SOURCE
  end

  it 'flags an offense for a non bounded context module which contains a class (compact version)' do
    expect_offense(<<~SOURCE)
      class NotABoundedContext::SomeClass
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Class `NotABoundedContext::SomeClass` is not within a valid bounded context module. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
      end
    SOURCE
  end

  it 'flags an offense for a non bounded context module which contains a module' do
    expect_offense(<<~SOURCE)
      module NotABoundedContext
             ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
        module NotABoundedContextEither
        end
      end
    SOURCE
  end

  it 'flags an offense for a class which is not within a module' do
    expect_offense(<<~SOURCE)
      class AClassNotInAModule
            ^^^^^^^^^^^^^^^^^^ Class `AClassNotInAModule` is not within a valid bounded context module. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
      end
    SOURCE
  end

  it 'does not flag an offense for a bounded context module' do
    expect_no_offenses(<<~SOURCE)
      module RemoteDevelopment
      end
    SOURCE
  end

  it 'does not flag an offense for a class which IS within a bounded context' do
    expect_no_offenses(<<~SOURCE)
      module RemoteDevelopment
        class ABoundedContextClass
        end
      end
    SOURCE
  end

  it 'does not flag an offense for a module which IS within a bounded context' do
    expect_no_offenses(<<~SOURCE)
      module RemoteDevelopment
        module SomeModule
        end
      end
    SOURCE
  end

  it 'does not flag an offense for a class which is nested more than one module deep in a bounded context' do
    expect_no_offenses(<<~SOURCE)
      module RemoteDevelopment
        module Workspaces
          module Create
            class Authorizer
            end
          end
        end
      end
    SOURCE
  end

  it 'does not flag an offense for a platform module' do
    expect_no_offenses(<<~SOURCE)
      module Gitlab
      end
    SOURCE
  end

  it 'does not flag an offense for a class inside a platform module' do
    expect_no_offenses(<<~SOURCE)
      module Gitlab
        class SomeUtils
        end
      end
    SOURCE
  end

  describe 'EE extensions' do
    it 'does not flag an offense for an EE module inside a platform module' do
      expect_no_offenses(<<~SOURCE)
        module EE
          module Gitlab
            class SomeClass
            end
          end
        end
      SOURCE
    end

    it 'does not flag an offense for an EE module inside a bounded context namespace' do
      expect_no_offenses(<<~SOURCE)
        module EE
          module RemoteDevelopment
            class SomeClass
            end
          end
        end
      SOURCE
    end

    it 'does not flag an offense for an EE module inside a bounded context namespace (compact version)' do
      expect_no_offenses(<<~SOURCE)
        class EE::RemoteDevelopment::SomeClass
        end
      SOURCE
    end

    it 'flags an offense inside an EE module' do
      expect_offense(<<~SOURCE)
        module EE
          module NotABoundedContext
                 ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
            class SomeClass
            end
          end
        end
      SOURCE
    end

    it 'flags an offense inside an EE module (compact version)' do
      expect_offense(<<~SOURCE)
        module EE::NotABoundedContext
               ^^^^^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
          class SomeClass
          end
        end
      SOURCE
    end
  end

  describe 'GraphQL code' do
    it 'flags an offense for a mutation not in a bounded context' do
      expect_offense(<<~SOURCE)
        module Mutations
          module NotABoundedContext
                 ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
          end
        end
      SOURCE
    end

    it 'does not flag an offense for a mutation in a bounded context' do
      expect_no_offenses(<<~SOURCE)
        module Mutations
          module RemoteDevelopment
          end
        end
      SOURCE
    end

    it 'flags an offense for a type not in a bounded context' do
      expect_offense(<<~SOURCE)
        module Types
          module NotABoundedContext
                 ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
          end
        end
      SOURCE
    end

    it 'does not flag an offense for a type in a bounded context' do
      expect_no_offenses(<<~SOURCE)
        module Types
          module RemoteDevelopment
          end
        end
      SOURCE
    end

    it 'flags an offense for a permission type not in a bounded context' do
      expect_offense(<<~SOURCE)
        module Types
          module PermissionTypes
            module NotABoundedContext
                   ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
            end
          end
        end
      SOURCE
    end

    it 'flags an offense for a permission type not in a bounded context (compact)' do
      expect_offense(<<~SOURCE)
        module Types::PermissionTypes::NotABoundedContext
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
        end
      SOURCE
    end

    it 'does not flag an offense for a permission type in a bounded context' do
      expect_no_offenses(<<~SOURCE)
        module Types
          module PermissionTypes
            module RemoteDevelopment
            end
          end
        end
      SOURCE
    end

    it 'flags an offense for a resolver not in a bounded context' do
      expect_offense(<<~SOURCE)
        module Resolvers
          module NotABoundedContext
                 ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
          end
        end
      SOURCE
    end

    it 'does not flag an offense for a resolver in a bounded context' do
      expect_no_offenses(<<~SOURCE)
        module Resolvers
          module RemoteDevelopment
          end
        end
      SOURCE
    end

    it 'does not flag an offense for a resolver in a bounded context inside an EE extension' do
      expect_no_offenses(<<~SOURCE)
        module EE
          module Resolvers
            module RemoteDevelopment
            end
          end
        end
      SOURCE
    end

    it 'flags an offense for a resolver not in a bounded context inside an EE extension' do
      expect_offense(<<~SOURCE)
        module EE
          module Resolvers
            module NotABoundedContext
                   ^^^^^^^^^^^^^^^^^^ Module `NotABoundedContext` is not a valid bounded context. See https://docs.gitlab.com/ee/development/software_design#bounded-contexts.
            end
          end
        end
      SOURCE
    end
  end
end
