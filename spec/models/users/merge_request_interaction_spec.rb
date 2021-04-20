# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Users::MergeRequestInteraction do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  subject(:interaction) do
    ::Users::MergeRequestInteraction.new(user: user, merge_request: merge_request.reset)
  end

  describe 'declarative policy delegation' do
    it 'delegates to the merge request' do
      expect(subject.declarative_policy_subject).to eq(merge_request)
    end
  end

  describe '#can_merge?' do
    context 'when the user cannot merge' do
      it { is_expected.not_to be_can_merge }
    end

    context 'when the user can merge' do
      before do
        project.add_maintainer(user)
      end

      it { is_expected.to be_can_merge }
    end
  end

  describe '#can_update?' do
    context 'when the user cannot update the MR' do
      it { is_expected.not_to be_can_update }
    end

    context 'when the user can update the MR' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to be_can_update }
    end
  end

  describe '#review_state' do
    subject { interaction.review_state }

    context 'when the user has not been asked to review the MR' do
      it { is_expected.to be_nil }

      it 'implies not reviewed' do
        expect(interaction).not_to be_reviewed
      end
    end

    context 'when the user has been asked to review the MR' do
      before do
        merge_request.reviewers << user
      end

      it { is_expected.to eq(Types::MergeRequestReviewStateEnum.values['UNREVIEWED'].value) }

      it 'implies not reviewed' do
        expect(interaction).not_to be_reviewed
      end
    end

    context 'when the user has provided a review' do
      before do
        merge_request.merge_request_reviewers.create!(reviewer: user, state: MergeRequestReviewer.states['reviewed'])
      end

      it { is_expected.to eq(Types::MergeRequestReviewStateEnum.values['REVIEWED'].value) }

      it 'implies reviewed' do
        expect(interaction).to be_reviewed
      end
    end
  end

  describe '#approved?' do
    context 'when the user has not approved the MR' do
      it { is_expected.not_to be_approved }
    end

    context 'when the user has approved the MR' do
      before do
        merge_request.approved_by_users << user
      end

      it { is_expected.to be_approved }
    end
  end
end
