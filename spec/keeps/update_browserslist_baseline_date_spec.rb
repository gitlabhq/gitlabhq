# frozen_string_literal: true

require 'tmpdir'
require 'spec_helper'
require './keeps/update_browserslist_baseline_date'

RSpec.describe Keeps::UpdateBrowserslistBaselineDate, time_travel_to: '2026-11-12', feature_category: :tooling do
  subject(:keep) { described_class.new }

  let(:tmp_dir) { Dir.mktmpdir }
  let(:browserslistrc_path) { File.join(tmp_dir, '.browserslistrc') }
  let(:pinned_date) { '2026-10-01' }
  let(:roulette) { instance_double(Keeps::Helpers::ReviewerRoulette) }

  before do
    File.write(browserslistrc_path, <<~BROWSERSLISTRC)
      # https://browsersl.ist/#q=baseline%20widely%20available%20on%20#{pinned_date}

      baseline widely available on #{pinned_date}
    BROWSERSLISTRC

    stub_const("#{described_class}::BROWSERSLISTRC_PATH", browserslistrc_path)
    allow(Keeps::Helpers::ReviewerRoulette).to receive(:instance).and_return(roulette)
    allow(roulette).to receive(:random_reviewer_for)
      .with('maintainer::frontend', identifiers: %w[UpdateBrowserslistBaselineDate 2026-11-01])
      .and_return('reviewer')
  end

  after do
    FileUtils.remove_entry(tmp_dir)
  end

  describe '#recreate_when_closed?' do
    it 'returns true so that a closed MR does not stop the following months' do
      expect(keep.recreate_when_closed?).to be(true)
    end
  end

  describe '#each_identified_change' do
    context 'when the pinned date is before the first day of the current month' do
      it 'yields one change with an identifier that does not depend on the date' do
        expect { |block| keep.each_identified_change(&block) }
          .to yield_with_args(have_attributes(
            identifiers: ['UpdateBrowserslistBaselineDate'],
            context: { from: '2026-10-01', to: '2026-11-01' }
          ))
      end
    end

    context 'when the pinned date is the first day of the current month or later' do
      let(:pinned_date) { '2026-11-01' }

      it 'does not yield a change' do
        expect { |block| keep.each_identified_change(&block) }.not_to yield_control
      end
    end

    context 'when the query has no date' do
      before do
        File.write(browserslistrc_path, "baseline widely available\n")
      end

      it 'does not yield a change' do
        expect { |block| keep.each_identified_change(&block) }.not_to yield_control
      end
    end
  end

  describe '#make_change!' do
    let(:change) { ::Gitlab::Housekeeper::Change.new }

    before do
      change.identifiers = ['UpdateBrowserslistBaselineDate']
      change.context = { from: '2026-10-01', to: '2026-11-01' }
    end

    it 'moves the date in the query and in the comments', :aggregate_failures do
      keep.make_change!(change)

      expect(File.read(browserslistrc_path)).to eq(<<~BROWSERSLISTRC)
        # https://browsersl.ist/#q=baseline%20widely%20available%20on%202026-11-01

        baseline widely available on 2026-11-01
      BROWSERSLISTRC
      expect(change).to have_attributes(
        title: 'Update the Baseline date in .browserslistrc to 2026-11-01',
        labels: described_class::LABELS,
        reviewers: ['reviewer'],
        changed_files: [browserslistrc_path]
      )
      expect(change.description).to include(
        'from 2026-10-01 to 2026-11-01',
        'https://browsersl.ist/#q=baseline%20widely%20available%20on%202026-10-01',
        'https://browsersl.ist/#q=baseline%20widely%20available%20on%202026-11-01'
      )
    end

    it 'leaves the labels mutable for the label that the runner adds' do
      keep.make_change!(change)
      change.add_standard_data!

      expect(change.labels).to eq(described_class::LABELS + [::Gitlab::Housekeeper::Change::HOUSEKEEPER_LABEL])
    end
  end
end
