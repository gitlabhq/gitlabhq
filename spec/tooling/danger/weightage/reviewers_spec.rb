# frozen_string_literal: true

require_relative '../../../../tooling/danger/weightage/reviewers'

RSpec.describe Tooling::Danger::Weightage::Reviewers do
  let(:multiplier) { Tooling::Danger::Weightage::CAPACITY_MULTIPLIER }
  let(:regular_reviewer) { double('Teammate', hungry: false, reduced_capacity: false) }
  let(:hungry_reviewer) { double('Teammate', hungry: true, reduced_capacity: false) }
  let(:reduced_capacity_reviewer) { double('Teammate', hungry: false, reduced_capacity: true) }
  let(:reviewers) do
    [
      hungry_reviewer,
      regular_reviewer,
      reduced_capacity_reviewer
    ]
  end

  let(:regular_traintainer) { double('Teammate', hungry: false, reduced_capacity: false) }
  let(:hungry_traintainer) { double('Teammate', hungry: true, reduced_capacity: false) }
  let(:reduced_capacity_traintainer) { double('Teammate', hungry: false, reduced_capacity: true) }
  let(:traintainers) do
    [
      hungry_traintainer,
      regular_traintainer,
      reduced_capacity_traintainer
    ]
  end

  let(:hungry_reviewer_count) { Tooling::Danger::Weightage::BASE_REVIEWER_WEIGHT * multiplier + described_class::DEFAULT_REVIEWER_WEIGHT }
  let(:hungry_traintainer_count) { described_class::TRAINTAINER_WEIGHT * multiplier + described_class::DEFAULT_REVIEWER_WEIGHT }
  let(:reviewer_count) { Tooling::Danger::Weightage::BASE_REVIEWER_WEIGHT * multiplier }
  let(:traintainer_count) { Tooling::Danger::Weightage::BASE_REVIEWER_WEIGHT * described_class::TRAINTAINER_WEIGHT * multiplier }
  let(:reduced_capacity_reviewer_count) { Tooling::Danger::Weightage::BASE_REVIEWER_WEIGHT }
  let(:reduced_capacity_traintainer_count) { described_class::TRAINTAINER_WEIGHT }

  subject(:weighted_reviewers) { described_class.new(reviewers, traintainers).execute }

  describe '#execute', :aggregate_failures do
    it 'weights the reviewers overall' do
      reviewers_count = hungry_reviewer_count + reviewer_count + reduced_capacity_reviewer_count
      traintainers_count = hungry_traintainer_count + traintainer_count + reduced_capacity_traintainer_count

      expect(weighted_reviewers.count).to eq reviewers_count + traintainers_count
    end

    it 'has total count of hungry reviewers and traintainers' do
      expect(weighted_reviewers.count(&:hungry)).to eq hungry_reviewer_count + hungry_traintainer_count
      expect(weighted_reviewers.count { |r| r.object_id == hungry_reviewer.object_id }).to eq hungry_reviewer_count
      expect(weighted_reviewers.count { |r| r.object_id == hungry_traintainer.object_id }).to eq hungry_traintainer_count
    end

    it 'has total count of regular reviewers and traintainers' do
      expect(weighted_reviewers.count { |r| r.object_id == regular_reviewer.object_id }).to eq reviewer_count
      expect(weighted_reviewers.count { |r| r.object_id == regular_traintainer.object_id }).to eq traintainer_count
    end

    it 'has count of reduced capacity reviewers' do
      expect(weighted_reviewers.count(&:reduced_capacity)).to eq reduced_capacity_reviewer_count + reduced_capacity_traintainer_count
      expect(weighted_reviewers.count { |r| r.object_id == reduced_capacity_reviewer.object_id }).to eq reduced_capacity_reviewer_count
      expect(weighted_reviewers.count { |r| r.object_id == reduced_capacity_traintainer.object_id }).to eq reduced_capacity_traintainer_count
    end
  end
end
