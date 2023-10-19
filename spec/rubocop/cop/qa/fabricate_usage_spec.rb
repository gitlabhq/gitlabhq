# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/qa/fabricate_usage'

RSpec.describe RuboCop::Cop::QA::FabricateUsage, feature_category: :quality_management do
  let(:source_file) { 'qa/qa/specs/spec.rb' }

  it 'registers an offense when using fabricate_via_api! for a valid resource' do
    expect_offense(<<~RUBY)
      Resource::Project.fabricate_via_api! do |project|
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer create(:project[, ...]) here.
        project.name = 'test'
      end
    RUBY
  end

  it 'registers an offense for groups' do
    expect_offense(<<~RUBY)
      Resource::Group.fabricate_via_api! do |group|
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer create(:group[, ...]) here.
        group.path = 'test'
      end
    RUBY
  end

  it 'does not register an offense when using fabricate_via_api! for an unenforced resource' do
    expect_no_offenses(<<~RUBY)
      Resource::Invalid.fabricate_via_api! do |project|
        project.name = 'test'
      end
    RUBY
  end
end
