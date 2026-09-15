# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../../rubocop/cop/gitlab/ai/avoid_foundational_flow_string_lookup'

RSpec.describe RuboCop::Cop::Gitlab::Ai::AvoidFoundationalFlowStringLookup, feature_category: :duo_agent_platform do
  offense_message = 'Avoid looking up `FoundationalFlow` via `find_by_reference`, ' \
    '`find_by(foundational_flow_reference: ...)`, or `[]` -- a hardcoded reference typo silently ' \
    'returns nil. Use the generated named accessor instead (e.g. `FoundationalFlow.code_review_v1`).'

  shared_examples 'raises rubocop offense' do |code|
    it "registers an offense for #{code}" do
      expect_offense(<<~RUBY)
        #{code}
        #{'^' * code.length} #{offense_message}
      RUBY
    end
  end

  context 'with a hardcoded string reference' do
    it_behaves_like 'raises rubocop offense', "FoundationalFlow.find_by_reference('code_review/v1')"
    it_behaves_like 'raises rubocop offense', "FoundationalFlow.find_by(foundational_flow_reference: 'code_review/v1')"
    it_behaves_like 'raises rubocop offense', "FoundationalFlow['code_review/v1']"
  end

  context 'with a dynamic reference' do
    it_behaves_like 'raises rubocop offense', 'FoundationalFlow.find_by_reference(workflow_definition)'
    it_behaves_like 'raises rubocop offense',
      'FoundationalFlow.find_by(foundational_flow_reference: workflow_definition)'
    it_behaves_like 'raises rubocop offense', 'FoundationalFlow[workflow_definition]'
    it_behaves_like 'raises rubocop offense', 'FoundationalFlow[workflow.workflow_definition]'
    it_behaves_like 'raises rubocop offense', 'FoundationalFlow[@flow_definition]'
  end

  context 'with a fully-qualified constant' do
    it_behaves_like 'raises rubocop offense', "Ai::Catalog::FoundationalFlow['code_review/v1']"
    it_behaves_like 'raises rubocop offense', "::Ai::Catalog::FoundationalFlow['code_review/v1']"
  end

  context 'with additional find_by conditions' do
    it_behaves_like 'raises rubocop offense',
      "FoundationalFlow.find_by(foundational_flow_reference: 'code_review/v1', beta: false)"
  end

  it 'does not raise an offense for the named accessor' do
    expect_no_offenses(<<~RUBY)
      FoundationalFlow.code_review_v1
    RUBY
  end

  it 'does not raise an offense for unrelated method chains' do
    expect_no_offenses(<<~RUBY)
      Item.find_by(foundational_flow_reference: 'code_review/v1')
      described_class.find_by(foundational_flow_reference: 'code_review/v1')
      FoundationalChatAgent.find_by_reference('chat')
    RUBY
  end
end
