# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::WildcardBranchFilterValidator do
  let(:validator) { described_class.new(attributes: [:push_events_branch_filter]) }
  let(:hook) { build(:project_hook) }

  describe '#validates_each' do
    it 'allows valid branch names' do
      validator.validate_each(hook, :push_events_branch_filter, +"good_branch_name")
      validator.validate_each(hook, :push_events_branch_filter, +"another/good_branch_name")
      expect(hook.errors.empty?).to be true
    end

    it 'disallows bad branch names' do
      validator.validate_each(hook, :push_events_branch_filter, +"bad branch~name")
      expect(hook.errors[:push_events_branch_filter].empty?).to be false
    end

    it 'allows wildcards' do
      validator.validate_each(hook, :push_events_branch_filter, +"features/*")
      validator.validate_each(hook, :push_events_branch_filter, +"features/*/bla")
      validator.validate_each(hook, :push_events_branch_filter, +"*-stable")
      expect(hook.errors.empty?).to be true
    end

    it 'gets rid of whitespace' do
      filter = +' master '
      validator.validate_each(hook, :push_events_branch_filter, filter)

      expect(filter).to eq 'master'
    end

    # Branch names can be quite long but in practice aren't over 255 so 4000 should
    # be enough space for a list of branch names but we can increase if needed.
    it 'limits length to 4000 chars' do
      filter = 'a' * 4001
      validator.validate_each(hook, :push_events_branch_filter, filter)

      expect(hook.errors[:push_events_branch_filter].empty?).to be false
    end
  end
end
