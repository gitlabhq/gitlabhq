# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'
require_relative '../../../../rubocop/cop/gitlab/avoid_user_organization'

RSpec.describe RuboCop::Cop::Gitlab::AvoidUserOrganization, feature_category: :organization do
  describe 'bad examples' do
    shared_examples 'registers an offense' do
      it 'registers an offense' do
        expect_offense(<<~RUBY, node: node_value)
          %{node}
          ^{node} Avoid calling `organization` on User objects. [...]
        RUBY
      end
    end

    context 'when calling organization on user variable' do
      let(:node_value) { 'user.organization' }

      include_examples 'registers an offense'
    end

    context 'when calling organization on current_user' do
      let(:node_value) { 'current_user.organization' }

      include_examples 'registers an offense'
    end

    context 'when calling organization on @user instance variable' do
      let(:node_value) { '@user.organization' }

      include_examples 'registers an offense'
    end

    context 'when calling organization on @current_user instance variable' do
      let(:node_value) { '@current_user.organization' }

      include_examples 'registers an offense'
    end

    context 'when calling organization on other_user' do
      let(:node_value) { 'other_user.organization' }

      include_examples 'registers an offense'
    end

    context 'when calling organization on @@user class variable' do
      let(:node_value) { '@@user.organization' }

      include_examples 'registers an offense'
    end

    context 'when used in assignment' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          org = user.organization
                ^^^^^^^^^^^^^^^^^ Avoid calling `organization` on User objects. [...]
        RUBY
      end
    end

    context 'when used in a conditional' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          if user.organization.present?
             ^^^^^^^^^^^^^^^^^ Avoid calling `organization` on User objects. [...]
            do_something
          end
        RUBY
      end
    end

    context 'when used in method call' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          do_something(user.organization)
                       ^^^^^^^^^^^^^^^^^ Avoid calling `organization` on User objects. [...]
        RUBY
      end
    end
  end

  describe 'good examples' do
    it 'does not register an offense for project.organization' do
      expect_no_offenses('project.organization')
    end

    it 'does not register an offense for group.organization' do
      expect_no_offenses('group.organization')
    end

    it 'does not register an offense for namespace.organization' do
      expect_no_offenses('namespace.organization')
    end

    it 'does not register an offense for organization_user.organization (join model)' do
      expect_no_offenses('organization_user.organization')
    end

    it 'does not register an offense for organization_users' do
      expect_no_offenses('organization_users.each { |ou| ou.organization }')
    end

    it 'does not register an offense for just accessing user' do
      expect_no_offenses('user')
    end

    it 'does not register an offense for user.name' do
      expect_no_offenses('user.name')
    end

    it 'does not register an offense for Current.organization' do
      expect_no_offenses('Current.organization')
    end

    it 'does not register an offense for @organization' do
      expect_no_offenses('@organization')
    end

    it 'does not register an offense for organization parameter' do
      expect_no_offenses(<<~RUBY)
        def initialize(organization:)
          @organization = organization
        end
      RUBY
    end
  end
end
