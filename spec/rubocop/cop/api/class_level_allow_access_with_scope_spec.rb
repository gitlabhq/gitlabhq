# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/class_level_allow_access_with_scope'

RSpec.describe RuboCop::Cop::API::ClassLevelAllowAccessWithScope, feature_category: :shared do
  let(:msg) { described_class::MSG }

  context "when there is no `allow_access_with_scope`" do
    it "does not add an offense" do
      expect_no_offenses(<<~CODE)
        class MyClass < ::API::Base
          include APIGuard
          namespace 'my_namespace' do

          end
        end
      CODE
    end
  end

  context "when there is class level `allow_access_with_scope`" do
    it "does not add an offense" do
      expect_no_offenses(<<~CODE)
        class MyClass < ::API::Base
          include APIGuard
          allow_access_with_scope :my_scope
          namespace 'my_namespace' do

          end
        end
      CODE
    end
  end

  context "when there is `allow_access_with_scope` under namespace" do
    it "adds an offense" do
      expect_offense(<<~CODE)
        class MyClass < ::API::Base
          include APIGuard
          namespace 'my_namespace' do
             allow_access_with_scope :my_scope
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
          end
        end
      CODE
    end
  end

  context "when there is `allow_access_with_scope` under group" do
    it "adds an offense" do
      expect_offense(<<~CODE)
        class MyClass < ::API::Base
          include APIGuard
          group 'my_namespace' do
             allow_access_with_scope :my_scope
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
          end
        end
      CODE
    end
  end

  context "when there is `allow_access_with_scope` under resource" do
    it "adds an offense" do
      expect_offense(<<~CODE)
        class MyClass < ::API::Base
          include APIGuard
          resource 'my_namespace' do
             allow_access_with_scope :my_scope
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
          end
        end
      CODE
    end
  end

  context "when there is `allow_access_with_scope` under resources" do
    it "adds an offense" do
      expect_offense(<<~CODE)
        class MyClass < ::API::Base
          include APIGuard
          resources 'my_namespace' do
             allow_access_with_scope :my_scope
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
          end
        end
      CODE
    end
  end

  context "when there is `allow_access_with_scope` under segment" do
    it "adds an offense" do
      expect_offense(<<~CODE)
        class MyClass < ::API::Base
          include APIGuard
          segment 'my_namespace' do
             allow_access_with_scope :my_scope
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
          end
        end
      CODE
    end
  end

  context "when there are `allow_access_with_scope`s both class level and under namespace" do
    it "adds an offense" do
      expect_offense(<<~CODE)
        class MyClass < ::API::Base
          include APIGuard
          allow_access_with_scope :my_scope
          namespace 'my_namespace' do
             allow_access_with_scope :my_scope
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
          end
        end
      CODE
    end
  end
end
