# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../../rubocop/cop/gitlab/authz/role_check_in_rule'

RSpec.describe RuboCop::Cop::Gitlab::Authz::RoleCheckInRule,
  feature_category: :permissions do
  context 'when can?(:*_access) is used inside a rule' do
    it 'registers an offense for a standalone role check' do
      expect_offense(<<~RUBY)
        rule { can?(:developer_access) }.enable :read_foo
                    ^^^^^^^^^^^^^^^^^ Avoid role-based checks (can?(:*_access)) in policy rules.
      RUBY
    end

    it 'registers an offense when negated with ~' do
      expect_offense(<<~RUBY)
        rule { ~can?(:developer_access) }.prevent :read_foo
                     ^^^^^^^^^^^^^^^^^ Avoid role-based checks (can?(:*_access)) in policy rules.
      RUBY
    end
  end

  context 'when combined with other conditions' do
    it 'registers an offense for &' do
      expect_offense(<<~RUBY)
        rule { feature_enabled & can?(:developer_access) }.enable :read_foo
                                      ^^^^^^^^^^^^^^^^^ Avoid role-based checks (can?(:*_access)) in policy rules.
      RUBY
    end

    it 'registers an offense for |' do
      expect_offense(<<~RUBY)
        rule { can?(:maintainer_access) | project_public }.enable :read_foo
                    ^^^^^^^^^^^^^^^^^^ Avoid role-based checks (can?(:*_access)) in policy rules.
      RUBY
    end

    it 'registers an offense when nested inside a larger expression' do
      expect_offense(<<~RUBY)
        rule { (feature_enabled & something_else) & can?(:developer_access) }.enable :read_foo
                                                         ^^^^^^^^^^^^^^^^^ Avoid role-based checks (can?(:*_access)) in policy rules.
      RUBY
    end
  end

  context 'when can? is not a role check' do
    it 'does not register an offense when symbol does not end in _access' do
      expect_no_offenses(<<~RUBY)
        rule { can?(:read_issue) }.enable :read_foo
      RUBY
    end
  end

  context 'when there are no conditions' do
    it 'does not register an offense for an empty rule body' do
      expect_no_offenses(<<~RUBY)
        rule { }.enable :read_foo
      RUBY
    end

    it 'does not register an offense for a numblock body' do
      expect_no_offenses(<<~RUBY)
        rule { _1 }.enable :read_foo
      RUBY
    end
  end

  # NOTE:
  # The early-return guards in `check_rule_block` protect against malformed or
  # unexpected AST nodes. They're hard/impossible to hit via real parsing
  # scenarios, so we use verifying doubles to exercise those branches.
  context 'when exercising internal branches of check_rule_block' do
    it 'returns early when send_node is nil' do
      node = instance_double(RuboCop::AST::BlockNode, send_node: nil, body: :anything)

      expect { cop.send(:check_rule_block, node) }.not_to raise_error
    end

    it 'returns early when send_node is not a send node (e.g. csend)' do
      send_node = instance_double(RuboCop::AST::SendNode, send_type?: false)
      node = instance_double(RuboCop::AST::BlockNode, send_node: send_node, body: :anything)

      expect { cop.send(:check_rule_block, node) }.not_to raise_error
    end

    it 'returns early when the block is not a rule block' do
      send_node = instance_double(RuboCop::AST::SendNode, send_type?: true, method?: false)
      node = instance_double(RuboCop::AST::BlockNode, send_node: send_node, body: :anything)

      expect { cop.send(:check_rule_block, node) }.not_to raise_error
    end
  end
end
