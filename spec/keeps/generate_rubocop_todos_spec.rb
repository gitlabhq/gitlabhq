# frozen_string_literal: true

require 'spec_helper'
require './keeps/generate_rubocop_todos'

RSpec.describe Keeps::GenerateRubocopTodos, feature_category: :tooling do
  let(:rake_task) { instance_double(Rake::Task) }
  let(:roulette) { instance_double(Keeps::Helpers::ReviewerRoulette) }
  let(:backend_reviewer) { 'john_doe' }
  let(:backend_maintainer) { 'raymond_smith' }

  subject(:keep) { described_class.new }

  before do
    allow(Rake::Task).to receive(:[]).with('rubocop:todo:generate').and_return(rake_task)
  end

  describe '#each_identified_change' do
    context 'when there are changes in the rubocop_todo directory' do
      before do
        allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
                                                 .with('git', 'status', '--short', described_class::RUBOCOP_TODO_DIR)
                                                 .and_return('M .rubocop_todo/some_cop.yml')

        allow(Keeps::Helpers::ReviewerRoulette).to receive(:new).and_return(roulette)

        allow(roulette).to receive(:random_reviewer_for).with('trainee maintainer::backend').and_return(nil)
        allow(roulette).to receive(:random_reviewer_for).with('reviewer::backend').and_return(backend_reviewer)
        allow(roulette).to receive(:random_reviewer_for).with('maintainer::backend').and_return(backend_maintainer)
      end

      it 'yields a Gitlab::Housekeeper::Change', :freeze_time do
        expect(Gitlab::Application).to receive(:load_tasks)
        expect(rake_task).to receive(:invoke)

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

      it 'yields nil' do
        expect(Gitlab::Application).to receive(:load_tasks)
        expect(rake_task).to receive(:invoke)

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
