# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Review do
  describe 'associations' do
    it { is_expected.to belong_to(:author).class_name('User').with_foreign_key(:author_id).inverse_of(:reviews) }
    it { is_expected.to belong_to(:merge_request).inverse_of(:reviews).touch(false) }
    it { is_expected.to belong_to(:project).inverse_of(:reviews) }

    it { is_expected.to have_many(:notes).order(:id).inverse_of(:review) }
  end

  describe 'modules' do
    it { is_expected.to include_module(Participable) }
    it { is_expected.to include_module(Mentionable) }
  end

  describe '#all_references' do
    it 'returns an extractor with the correct referenced users' do
      user1 = create(:user, username: "foo")
      user2 = create(:user, username: "bar")
      review = create(:review)
      project = review.project
      author = review.author

      create(:note, review: review, project: project, author: author, note: "cc @foo @non_existent")
      create(:note, review: review, project: project, author: author, note: "cc @bar")

      expect(review.all_references(author).users).to match_array([user1, user2])
    end
  end

  describe '#participants' do
    it 'includes the review author' do
      project = create(:project, :public)
      merge_request = create(:merge_request, source_project: project)
      review = create(:review, project: project, merge_request: merge_request)
      create(:note, review: review, noteable: merge_request, project: project, author: review.author)

      expect(review.participants).to include(review.author)
    end
  end

  describe '#from_merge_request_author?' do
    let(:merge_request) { build_stubbed(:merge_request) }
    let(:review) { build_stubbed(:review, merge_request: merge_request, author: author) }

    subject(:from_merge_request_author?) { review.from_merge_request_author? }

    context 'when review author is the merge request author' do
      let(:author) { merge_request.author }

      it { is_expected.to eq(true) }
    end

    context 'when review author is not the merge request author' do
      let(:author) { build_stubbed(:user) }

      it { is_expected.to eq(false) }
    end
  end
end
