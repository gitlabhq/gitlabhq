# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::ProcessAssignees do
  describe '#execute' do
    it 'returns assignee_ids when assignee_ids are specified' do
      process = Issuable::ProcessAssignees.new(assignee_ids: %w(5 7 9),
                                               add_assignee_ids: %w(2 4 6),
                                               remove_assignee_ids: %w(4 7 11),
                                               existing_assignee_ids: %w(1 3 9),
                                               extra_assignee_ids: %w(2 5 12))
      result = process.execute

      expect(result.sort).to eq(%w(5 7 9).sort)
    end

    it 'combines other ids when assignee_ids is empty' do
      process = Issuable::ProcessAssignees.new(assignee_ids: [],
                                               add_assignee_ids: %w(2 4 6),
                                               remove_assignee_ids: %w(4 7 11),
                                               existing_assignee_ids: %w(1 3 11),
                                               extra_assignee_ids: %w(2 5 12))
      result = process.execute

      expect(result.sort).to eq(%w(1 2 3 5 6 12).sort)
    end

    it 'combines other ids when assignee_ids is nil' do
      process = Issuable::ProcessAssignees.new(assignee_ids: nil,
                                               add_assignee_ids: %w(2 4 6),
                                               remove_assignee_ids: %w(4 7 11),
                                               existing_assignee_ids: %w(1 3 11),
                                               extra_assignee_ids: %w(2 5 12))
      result = process.execute

      expect(result.sort).to eq(%w(1 2 3 5 6 12).sort)
    end

    it 'combines other ids when assignee_ids and add_assignee_ids are nil' do
      process = Issuable::ProcessAssignees.new(assignee_ids: nil,
                                               add_assignee_ids: nil,
                                               remove_assignee_ids: %w(4 7 11),
                                               existing_assignee_ids: %w(1 3 11),
                                               extra_assignee_ids: %w(2 5 12))
      result = process.execute

      expect(result.sort).to eq(%w(1 2 3 5 12).sort)
    end

    it 'combines other ids when assignee_ids and remove_assignee_ids are nil' do
      process = Issuable::ProcessAssignees.new(assignee_ids: nil,
                                               add_assignee_ids: %w(2 4 6),
                                               remove_assignee_ids: nil,
                                               existing_assignee_ids: %w(1 3 11),
                                               extra_assignee_ids: %w(2 5 12))
      result = process.execute

      expect(result.sort).to eq(%w(1 2 4 3 5 6 11 12).sort)
    end

    it 'combines ids when only add_assignee_ids and remove_assignee_ids are passed' do
      process = Issuable::ProcessAssignees.new(assignee_ids: nil,
                                               add_assignee_ids: %w(2 4 6),
                                               remove_assignee_ids: %w(4 7 11))
      result = process.execute

      expect(result.sort).to eq(%w(2 6).sort)
    end
  end
end
