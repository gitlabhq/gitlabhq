# frozen_string_literal: true

require 'spec_helper'
require './keeps/cleanup_gl_introduced'

RSpec.describe Keeps::CleanupGlIntroduced, feature_category: :tooling do
  subject(:keep) { described_class.new }

  let(:changes) { { 'app/assets/javascripts/foo/query.graphql' => 2 } }
  let(:dry_run_cleanup) { instance_double(::CleanupGlIntroduced, execute: changes) }
  let(:cleanup) do
    instance_double(::CleanupGlIntroduced, execute: changes, cutoff_milestone_name: '19.4')
  end

  let(:roulette) { instance_double(Keeps::Helpers::ReviewerRoulette) }

  before do
    allow(::CleanupGlIntroduced).to receive(:new).with(hash_including(dry_run: true)).and_return(dry_run_cleanup)
    allow(::CleanupGlIntroduced).to receive(:new).with(hash_including(dry_run: false)).and_return(cleanup)
    allow(Keeps::Helpers::ReviewerRoulette).to receive(:instance).and_return(roulette)
    allow(roulette).to receive(:random_reviewer_for).with('maintainer::frontend').and_return('reviewer')
    allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
  end

  describe '#each_identified_change' do
    context 'when there are stale directives' do
      it 'yields one change with an identifier that does not depend on the milestone' do
        expect { |block| keep.each_identified_change(&block) }
          .to yield_with_args(have_attributes(identifiers: ['CleanupGlIntroduced']))
      end
    end

    context 'when there are no stale directives' do
      let(:changes) { {} }

      it 'does not yield a change' do
        expect { |block| keep.each_identified_change(&block) }.not_to yield_control
      end
    end
  end

  describe '#make_change!' do
    let(:change) { ::Gitlab::Housekeeper::Change.new }

    it 'removes the directives and describes the change' do
      keep.make_change!(change)

      expect(change).to have_attributes(
        title: 'Remove stale @gl_introduced directives',
        labels: described_class::LABELS,
        reviewers: ['reviewer'],
        changed_files: ['app/assets/javascripts/foo/query.graphql']
      )
      expect(change.description).to include(
        'older than 19.4',
        '`app/assets/javascripts/foo/query.graphql` (2)',
        'need manual cleanup'
      )
    end

    it 'formats the changed files with Prettier' do
      keep.make_change!(change)

      expect(::Gitlab::Housekeeper::Shell).to have_received(:execute)
        .with('yarn', 'run', 'prettier', '--write', 'app/assets/javascripts/foo/query.graphql')
    end
  end
end
