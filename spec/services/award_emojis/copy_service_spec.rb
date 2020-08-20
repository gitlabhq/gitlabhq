# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmojis::CopyService do
  let_it_be(:from_awardable) do
    create(:issue, award_emoji: [
      build(:award_emoji, name: 'thumbsup'),
      build(:award_emoji, name: 'thumbsdown')
    ])
  end

  describe '#initialize' do
    it 'validates that we cannot copy AwardEmoji to the same Awardable' do
      expect { described_class.new(from_awardable, from_awardable) }.to raise_error(ArgumentError)
    end
  end

  describe '#execute' do
    let(:to_awardable) { create(:issue) }

    subject(:execute_service) { described_class.new(from_awardable, to_awardable).execute }

    it 'copies AwardEmojis', :aggregate_failures do
      expect { execute_service }.to change { AwardEmoji.count }.by(2)
      expect(to_awardable.award_emoji.map(&:name)).to match_array(%w(thumbsup thumbsdown))
    end

    it 'returns success', :aggregate_failures do
      expect(execute_service).to be_kind_of(ServiceResponse)
      expect(execute_service).to be_success
    end
  end
end
