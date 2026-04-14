# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/avoid_direct_work_item_type_usage'

RSpec.describe RuboCop::Cop::Gitlab::AvoidDirectWorkItemTypeUsage, feature_category: :team_planning do
  shared_examples 'raises rubocop offense' do |code|
    it "registers offense for #{code}" do
      expect_offense(<<~RUBY)
      #{code}
      #{'^' * code.length} Avoid using `WorkItems::Type` or `WorkItems::TypesFramework::SystemDefined::Type` directly. [...]
      RUBY
    end
  end

  context 'when using WorkItems::Type directly' do
    it_behaves_like 'raises rubocop offense', 'WorkItems::Type.default_by_type(:issue)'
    it_behaves_like 'raises rubocop offense', '::WorkItems::Type.default_by_type(:issue)'
    it_behaves_like 'raises rubocop offense', 'WorkItems::Type.default_issue_type'
    it_behaves_like 'raises rubocop offense', 'WorkItems::Type.base_types'
    it_behaves_like 'raises rubocop offense', 'WorkItems::Type.where(name: "Issue")'
    it_behaves_like 'raises rubocop offense', 'WorkItems::Type.find_by(id: 1)'
    it_behaves_like 'raises rubocop offense', 'WorkItems::Type.id_in([1, 2])'
    it_behaves_like 'raises rubocop offense', 'WorkItems::Type.by_type(:issue)'
    it_behaves_like 'raises rubocop offense', 'WorkItems::Type.all'
  end

  context 'when using WorkItems::TypesFramework::SystemDefined::Type directly' do
    it_behaves_like 'raises rubocop offense', 'WorkItems::TypesFramework::SystemDefined::Type.all'
    it_behaves_like 'raises rubocop offense', '::WorkItems::TypesFramework::SystemDefined::Type.all'
    it_behaves_like 'raises rubocop offense', 'WorkItems::TypesFramework::SystemDefined::Type.find_by(id: 1)'
    it_behaves_like 'raises rubocop offense', 'WorkItems::TypesFramework::SystemDefined::Type.default_issue_type'
  end

  it 'does not raise an offense when using the Provider' do
    expect_no_offenses(<<~RUBY)
      WorkItems::TypesFramework::Provider.new(namespace).find_by_base_type(:issue)
    RUBY
  end

  it 'does not raise an offense for unrelated models' do
    expect_no_offenses(<<~RUBY)
      SomeOtherModel.where(name: "Issue")
    RUBY
  end

  it 'does not raise an offense for constant access' do
    expect_no_offenses(<<~RUBY)
      WorkItems::Type::TYPE_NAMES
    RUBY
  end
end
