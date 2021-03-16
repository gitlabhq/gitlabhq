# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::ProcessAssignees do
  describe '#execute' do
    it 'returns assignee_ids when add_assignee_ids and remove_assignee_ids are not specified' do
      process = Issuable::ProcessAssignees.new(assignee_ids: %w(5 7 9),
                                               add_assignee_ids: nil,
                                               remove_assignee_ids: nil,
                                               existing_assignee_ids: %w(1 3 9),
                                               extra_assignee_ids: %w(2 5 12))
      result = process.execute

      expect(result.sort).to eq(%w(5 7 9).sort)
    end

    it 'combines other ids when assignee_ids is nil' do
      process = Issuable::ProcessAssignees.new(assignee_ids: nil,
                                               add_assignee_ids: nil,
                                               remove_assignee_ids: nil,
                                               existing_assignee_ids: %w(1 3 11),
                                               extra_assignee_ids: %w(2 5 12))
      result = process.execute

      expect(result.sort).to eq(%w(1 2 3 5 11 12).sort)
    end

    it 'combines other ids when both add_assignee_ids and remove_assignee_ids are not empty' do
      process = Issuable::ProcessAssignees.new(assignee_ids: %w(5 7 9),
                                               add_assignee_ids: %w(2 4 6),
                                               remove_assignee_ids: %w(4 7 11),
                                               existing_assignee_ids: %w(1 3 11),
                                               extra_assignee_ids: %w(2 5 12))
      result = process.execute

      expect(result.sort).to eq(%w(1 2 3 5 6 12).sort)
    end

    it 'combines other ids when remove_assignee_ids is not empty' do
      process = Issuable::ProcessAssignees.new(assignee_ids: %w(5 7 9),
                                               add_assignee_ids: nil,
                                               remove_assignee_ids: %w(4 7 11),
                                               existing_assignee_ids: %w(1 3 11),
                                               extra_assignee_ids: %w(2 5 12))
      result = process.execute

      expect(result.sort).to eq(%w(1 2 3 5 12).sort)
    end

    it 'combines other ids when add_assignee_ids is not empty' do
      process = Issuable::ProcessAssignees.new(assignee_ids: %w(5 7 9),
                                               add_assignee_ids: %w(2 4 6),
                                               remove_assignee_ids: nil,
                                               existing_assignee_ids: %w(1 3 11),
                                               extra_assignee_ids: %w(2 5 12))
      result = process.execute

      expect(result.sort).to eq(%w(1 2 4 3 5 6 11 12).sort)
    end

    it 'combines ids when existing_assignee_ids and extra_assignee_ids are omitted' do
      process = Issuable::ProcessAssignees.new(assignee_ids: %w(5 7 9),
                                               add_assignee_ids: %w(2 4 6),
                                               remove_assignee_ids: %w(4 7 11))
      result = process.execute

      expect(result.sort).to eq(%w(2 6).sort)
    end
  end
end
