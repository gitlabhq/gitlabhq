# frozen_string_literal: true

require 'gitlab/danger/weightage/maintainers'

RSpec.describe Gitlab::Danger::Weightage::Maintainers do
  let(:multiplier) { Gitlab::Danger::Weightage::CAPACITY_MULTIPLIER }
  let(:regular_maintainer) { double('Teammate', reduced_capacity: false) }
  let(:reduced_capacity_maintainer) { double('Teammate', reduced_capacity: true) }
  let(:maintainers) do
    [
      regular_maintainer,
      reduced_capacity_maintainer
    ]
  end

  let(:maintainer_count) { Gitlab::Danger::Weightage::BASE_REVIEWER_WEIGHT * multiplier }
  let(:reduced_capacity_maintainer_count) { Gitlab::Danger::Weightage::BASE_REVIEWER_WEIGHT }

  subject(:weighted_maintainers) { described_class.new(maintainers).execute }

  describe '#execute' do
    it 'weights the maintainers overall' do
      expect(weighted_maintainers.count).to eq maintainer_count + reduced_capacity_maintainer_count
    end

    it 'has total count of regular maintainers' do
      expect(weighted_maintainers.count { |r| r.object_id == regular_maintainer.object_id }).to eq maintainer_count
    end

    it 'has count of reduced capacity maintainers' do
      expect(weighted_maintainers.count { |r| r.object_id == reduced_capacity_maintainer.object_id }).to eq reduced_capacity_maintainer_count
    end
  end
end
