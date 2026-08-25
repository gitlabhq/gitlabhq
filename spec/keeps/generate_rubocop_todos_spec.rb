# frozen_string_literal: true

require 'spec_helper'
require './keeps/generate_rubocop_todos'

RSpec.describe Keeps::GenerateRubocopTodos, feature_category: :tooling do
  let(:roulette) { instance_double(Keeps::Helpers::ReviewerRoulette) }
  let(:todo_generator) { instance_double(Keeps::Helpers::RubocopTodoGenerator, generate: nil) }
  let(:grace_period_remover) { instance_double(Keeps::Helpers::RubocopGracePeriodRemover, remove_overdue: nil) }
  let(:backend_reviewer) { 'john_doe' }
  let(:backend_maintainer) { 'raymond_smith' }

  subject(:keep) { described_class.new }

  before do
    allow(Keeps::Helpers::RubocopTodoGenerator).to receive(:new).and_return(todo_generator)
    allow(Keeps::Helpers::RubocopGracePeriodRemover).to receive(:new).and_return(grace_period_remover)

    # Reset singleton to create a fresh instance
    Singleton.__init__(Keeps::Helpers::ReviewerRoulette)
    allow(Keeps::Helpers::ReviewerRoulette).to receive(:instance).and_return(roulette)
  end

  describe '#make_change!' do
    it 'regenerates todos and removes overdue grace periods' do
      expect(todo_generator).to receive(:generate)
      expect(grace_period_remover).to receive(:remove_overdue)
      allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
        .with('git', 'status', '--short', described_class::RUBOCOP_TODO_DIR)
        .and_return('')

      keep.each_identified_change { |change| keep.make_change!(change) }
    end

    context 'when there are changes in the rubocop_todo directory' do
      before do
        allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', 'status', '--short', described_class::RUBOCOP_TODO_DIR)
          .and_return('M .rubocop_todo/some_cop.yml')

        allow(roulette).to receive(:random_reviewer_for).with('trainee maintainer::backend').and_return(nil)
        allow(roulette).to receive(:random_reviewer_for).with('reviewer::backend').and_return(backend_reviewer)
        allow(roulette).to receive(:random_reviewer_for).with('maintainer::backend').and_return(backend_maintainer)
      end

      it 'yields a populated Gitlab::Housekeeper::Change', :freeze_time do
        actual_change = nil
        keep.each_identified_change do |change|
          keep.make_change!(change)
          actual_change = change
        end

        expect(actual_change).to be_a(Gitlab::Housekeeper::Change)
        expect(actual_change.title).to eq(described_class::TITLE)
        expect(actual_change.description).to eq(described_class::DESCRIPTION)
        expect(actual_change.identifiers).to eq(keep.send(:change_identifiers))
        expect(actual_change.changed_files).to contain_exactly('.rubocop_todo')
        expect(actual_change.assignees).to eq([backend_reviewer])
        expect(actual_change.reviewers).to eq([backend_maintainer])
        expect(actual_change.labels).to eq(keep.send(:labels))
      end
    end

    context 'when there are no changes in the rubocop_todo directory' do
      before do
        allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', 'status', '--short', described_class::RUBOCOP_TODO_DIR)
          .and_return('')
      end

      it 'leaves the change unpopulated' do
        actual_change = nil
        keep.each_identified_change do |change|
          keep.make_change!(change)
          actual_change = change
        end

        expect(actual_change).to be_a(Gitlab::Housekeeper::Change)
        expect(actual_change.title).to be_nil
        expect(actual_change.description).to be_nil
      end
    end
  end
end
