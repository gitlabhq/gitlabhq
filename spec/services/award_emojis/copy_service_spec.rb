# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmojis::CopyService, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :in_group) }
  let_it_be(:custom_emoji_in_origin_namespace) { create(:custom_emoji, name: 'partyparrot', namespace: project.group) }
  let_it_be(:from_awardable) do
    create(:issue, project: project,
      award_emoji: [
        build(:award_emoji, name: AwardEmoji::THUMBS_UP),
        build(:award_emoji, name: AwardEmoji::THUMBS_DOWN),
        build(:award_emoji, name: custom_emoji_in_origin_namespace.name)
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

    it 'copies AwardEmojis that exist in the destination namespace', :aggregate_failures do
      expect { execute_service }.to change { AwardEmoji.count }.by(2)
      expect(to_awardable.award_emoji.map(&:name)).to match_array([AwardEmoji::THUMBS_UP, AwardEmoji::THUMBS_DOWN])
    end

    it 'returns success', :aggregate_failures do
      expect(execute_service).to be_kind_of(ServiceResponse)
      expect(execute_service).to be_success
    end
  end
end
