# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmoji do
  describe 'Associations' do
    it { is_expected.to belong_to(:awardable) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'modules' do
    it { is_expected.to include_module(Participable) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:awardable) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:name) }

    # To circumvent a bug in the shoulda matchers
    describe "scoped uniqueness validation" do
      it "rejects duplicate award emoji" do
        user  = create(:user)
        issue = create(:issue)
        create(:award_emoji, user: user, awardable: issue)
        new_award = build(:award_emoji, user: user, awardable: issue)

        expect(new_award).not_to be_valid
      end

      # Assume User A and User B both created award emoji of the same name
      # on the same awardable. When User A is deleted, User A's award emoji
      # is moved to the ghost user. When User B is deleted, User B's award emoji
      # also needs to be moved to the ghost user - this cannot happen unless
      # the uniqueness validation is disabled for ghost users.
      it "allows duplicate award emoji for ghost users" do
        user  = create(:user, :ghost)
        issue = create(:issue)
        create(:award_emoji, user: user, awardable: issue)
        new_award = build(:award_emoji, user: user, awardable: issue)

        expect(new_award).to be_valid
      end

      # Similar to allowing duplicate award emojis for ghost users,
      # when Importing a project that has duplicate award emoji placed by
      # ghost user we change the author to be importer user and allow
      # duplicates, otherwise relation containing such duplicates
      # fails to be created
      context 'when importing' do
        it 'allows duplicate award emoji' do
          user  = create(:user)
          issue = create(:issue)
          create(:award_emoji, user: user, awardable: issue)
          new_award = build(:award_emoji, user: user, awardable: issue, importing: true)

          expect(new_award).to be_valid
        end
      end
    end
  end

  describe 'scopes' do
    let_it_be(:thumbsup) { create(:award_emoji, name: 'thumbsup') }
    let_it_be(:thumbsdown) { create(:award_emoji, name: 'thumbsdown') }

    describe '.upvotes' do
      it { expect(described_class.upvotes).to contain_exactly(thumbsup) }
    end

    describe '.downvotes' do
      it { expect(described_class.downvotes).to contain_exactly(thumbsdown) }
    end

    describe '.named' do
      it { expect(described_class.named('thumbsup')).to contain_exactly(thumbsup) }
      it { expect(described_class.named(%w[thumbsup thumbsdown])).to contain_exactly(thumbsup, thumbsdown) }
    end

    describe '.awarded_by' do
      it { expect(described_class.awarded_by(thumbsup.user)).to contain_exactly(thumbsup) }
      it { expect(described_class.awarded_by([thumbsup.user, thumbsdown.user])).to contain_exactly(thumbsup, thumbsdown) }
    end
  end

  describe 'expiring ETag cache' do
    context 'on a note' do
      let(:note) { create(:note_on_issue) }
      let(:award_emoji) { build(:award_emoji, user: build(:user), awardable: note) }

      it 'calls expire_etag_cache on the note when saved' do
        expect(note).to receive(:expire_etag_cache)

        award_emoji.save!
      end

      it 'calls expire_etag_cache on the note when destroyed' do
        expect(note).to receive(:expire_etag_cache)

        award_emoji.destroy!
      end
    end

    context 'on another awardable' do
      let(:issue) { create(:issue) }
      let(:award_emoji) { build(:award_emoji, user: build(:user), awardable: issue) }

      it 'does not call expire_etag_cache on the issue when saved' do
        expect(issue).not_to receive(:expire_etag_cache)

        award_emoji.save!
      end

      it 'does not call expire_etag_cache on the issue when destroyed' do
        expect(issue).not_to receive(:expire_etag_cache)

        award_emoji.destroy!
      end
    end
  end

  describe 'bumping updated at' do
    let(:note) { create(:note_on_issue) }
    let(:award_emoji) { build(:award_emoji, user: build(:user), awardable: note) }

    it 'calls bump_updated_at on the note when saved' do
      expect(note).to receive(:bump_updated_at)

      award_emoji.save!
    end

    it 'calls bump_updated_at on the note when destroyed' do
      expect(note).to receive(:bump_updated_at)

      award_emoji.destroy!
    end

    context 'on another awardable' do
      let(:issue) { create(:issue) }
      let(:award_emoji) { build(:award_emoji, user: build(:user), awardable: issue) }

      it 'does not error out when saved' do
        expect { award_emoji.save! }.not_to raise_error
      end

      it 'does not error out when destroy' do
        expect { award_emoji.destroy! }.not_to raise_error
      end
    end
  end

  describe '.award_counts_for_user' do
    let(:user) { create(:user) }

    before do
      create(:award_emoji, user: user, name: 'thumbsup')
      create(:award_emoji, user: user, name: 'thumbsup')
      create(:award_emoji, user: user, name: 'thumbsdown')
      create(:award_emoji, user: user, name: '+1')
    end

    it 'returns the awarded emoji in descending order' do
      awards = described_class.award_counts_for_user(user)

      expect(awards).to eq('thumbsup' => 2, 'thumbsdown' => 1, '+1' => 1)
    end

    it 'limits the returned number of rows' do
      awards = described_class.award_counts_for_user(user, 1)

      expect(awards).to eq('thumbsup' => 2)
    end
  end
end
