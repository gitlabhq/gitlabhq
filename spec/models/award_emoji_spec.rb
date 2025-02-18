# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmoji, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }

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

    context 'custom emoji' do
      let_it_be(:group) { create(:group) }
      let_it_be(:emoji) { create(:custom_emoji, name: 'partyparrot', namespace: group) }
      let_it_be(:project) { create(:project, namespace: group) }

      before_all do
        group.add_maintainer(user)
      end

      shared_examples 'awardable' do
        it 'is accepted' do
          new_award = build(:award_emoji, user: user, awardable: awardable, name: emoji.name)
          expect(new_award).to be_valid
        end
      end

      context 'with issue' do
        let(:awardable) { create(:issue, project: project) }

        include_examples 'awardable'
      end

      context 'with merge_request' do
        let(:awardable) { create(:merge_request, source_project: project) }

        include_examples 'awardable'
      end

      context 'with note_on_issue' do
        let(:awardable) { create(:note_on_issue, project: project) }

        include_examples 'awardable'
      end

      context 'with snippet' do
        let(:awardable) { create(:project_snippet, project: project) }

        include_examples 'awardable'
      end

      it 'is accepted on subgroup issue' do
        subgroup = create(:group, parent: group)
        project = create(:project, namespace: subgroup)
        issue = create(:issue, project: project)
        new_award = build(:award_emoji, user: user, awardable: issue, name: emoji.name)

        expect(new_award).to be_valid
      end

      it 'is not supported on personal snippet (yet)' do
        snippet = create(:personal_snippet)
        new_award = build(:award_emoji, user: snippet.author, awardable: snippet, name: 'null')

        expect(new_award).not_to be_valid
      end
    end
  end

  describe 'scopes' do
    let_it_be(:awardable1) { create(:issue) }
    let_it_be(:awardable2) { create(:issue) }
    let_it_be(:thumbsup) { create(:award_emoji, name: 'thumbsup', awardable: awardable1) }
    let_it_be(:thumbsdown) { create(:award_emoji, name: 'thumbsdown', awardable: awardable2) }

    let(:awardables) { [awardable1, awardable2] }

    describe '.upvotes' do
      it { expect(described_class.upvotes).to contain_exactly(thumbsup) }
    end

    describe '.downvotes' do
      it { expect(described_class.downvotes).to contain_exactly(thumbsdown) }
    end

    describe '.named' do
      it { expect(described_class.named(AwardEmoji::THUMBS_UP)).to contain_exactly(thumbsup) }
      it { expect(described_class.named([AwardEmoji::THUMBS_UP, AwardEmoji::THUMBS_DOWN])).to contain_exactly(thumbsup, thumbsdown) }
    end

    describe '.awarded_by' do
      it { expect(described_class.awarded_by(thumbsup.user)).to contain_exactly(thumbsup) }
      it { expect(described_class.awarded_by([thumbsup.user, thumbsdown.user])).to contain_exactly(thumbsup, thumbsdown) }
    end

    describe '.by_awardable' do
      it { expect(described_class.by_awardable('Issue', awardables)).to match_array([thumbsup, thumbsdown]) }
      it { expect(described_class.by_awardable('Issue', awardables.map(&:id))).to match_array([thumbsup, thumbsdown]) }
    end
  end

  describe 'broadcasting updates' do
    context 'on a note' do
      let(:note) { create(:note_on_issue) }
      let(:award_emoji) { build(:award_emoji, user: user, awardable: note) }

      it 'broadcasts updates on the note when saved' do
        expect(note).to receive(:broadcast_noteable_notes_changed)
        expect(note).to receive(:trigger_note_subscription_update)

        award_emoji.save!
      end

      it 'broadcasts updates on the note when destroyed' do
        award_emoji.save!

        expect(note).to receive(:broadcast_noteable_notes_changed)
        expect(note).to receive(:trigger_note_subscription_update)

        award_emoji.destroy!
      end

      context 'when importing' do
        let(:award_emoji) { build(:award_emoji, user: user, awardable: note, importing: true) }

        it 'does not broadcast updates on the note when saved' do
          expect(note).not_to receive(:broadcast_noteable_notes_changed)
          expect(note).not_to receive(:trigger_note_subscription_update)

          award_emoji.save!
        end
      end
    end

    context 'on another awardable' do
      let(:issue) { create(:issue) }
      let(:award_emoji) { build(:award_emoji, user: user, awardable: issue) }

      it 'does not broadcast updates on the issue when saved' do
        expect(issue).not_to receive(:broadcast_noteable_notes_changed)
        expect(issue).not_to receive(:trigger_note_subscription_update)

        award_emoji.save!
      end

      it 'does not broadcast updates on the issue when destroyed' do
        award_emoji.save!

        expect(issue).not_to receive(:broadcast_noteable_notes_changed)
        expect(issue).not_to receive(:trigger_note_subscription_update)

        award_emoji.destroy!
      end
    end
  end

  describe 'bumping updated at' do
    let(:note) { create(:note_on_issue) }
    let(:award_emoji) { build(:award_emoji, user: user, awardable: note) }

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
      let(:award_emoji) { build(:award_emoji, user: user, awardable: issue) }

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
      create(:award_emoji, user: user, name: AwardEmoji::THUMBS_UP)
      create(:award_emoji, user: user, name: AwardEmoji::THUMBS_UP)
      create(:award_emoji, user: user, name: AwardEmoji::THUMBS_DOWN)
      create(:award_emoji, user: user, name: '+1')
    end

    it 'returns the awarded emoji in descending order' do
      awards = described_class.award_counts_for_user(user)

      expect(awards).to eq(AwardEmoji::THUMBS_UP => 2, AwardEmoji::THUMBS_DOWN => 1, '+1' => 1)
    end

    it 'limits the returned number of rows' do
      awards = described_class.award_counts_for_user(user, 1)

      expect(awards).to eq(AwardEmoji::THUMBS_UP => 2)
    end
  end

  describe 'updating upvotes_count' do
    context 'on an issue' do
      let(:issue) { create(:issue) }
      let(:upvote) { build(:award_emoji, :upvote, user: user, awardable: issue) }
      let(:downvote) { build(:award_emoji, :downvote, user: user, awardable: issue) }

      it 'updates upvotes_count on the issue when saved' do
        expect(issue).to receive(:update_column).with(:upvotes_count, 1).once

        upvote.save!
        downvote.save!
      end

      it 'updates upvotes_count on the issue when destroyed' do
        expect(issue).to receive(:update_column).with(:upvotes_count, 0).once

        upvote.destroy!
        downvote.destroy!
      end
    end

    context 'on another awardable' do
      let(:merge_request) { create(:merge_request) }
      let(:award_emoji) { build(:award_emoji, user: user, awardable: merge_request) }

      it 'does not update upvotes_count on the merge_request when saved' do
        expect(merge_request).not_to receive(:update_column)

        award_emoji.save!
      end

      it 'does not update upvotes_count on the merge_request when destroyed' do
        expect(merge_request).not_to receive(:update_column)

        award_emoji.destroy!
      end
    end
  end

  describe '#url' do
    let_it_be(:custom_emoji) { create(:custom_emoji) }
    let_it_be(:project) { create(:project, namespace: custom_emoji.group) }
    let_it_be(:issue) { create(:issue, project: project) }

    def build_award(name)
      build(:award_emoji, awardable: issue, name: name)
    end

    it 'is nil for built-in emoji' do
      new_award = build_award('tada')

      count = ActiveRecord::QueryRecorder.new do
        expect(new_award.url).to be_nil
      end.count
      expect(count).to be_zero
    end

    it 'is nil for unrecognized emoji' do
      new_award = build_award('null')

      expect(new_award.url).to be_nil
    end

    it 'is set for custom emoji' do
      new_award = build_award(custom_emoji.name)

      expect(new_award.url).to eq(custom_emoji.url)
    end

    describe 'when inside subgroup' do
      let_it_be(:subgroup) { create(:group, parent: custom_emoji.group) }
      let_it_be(:project) { create(:project, namespace: subgroup) }

      it 'is set for custom emoji' do
        new_award = build_award(custom_emoji.name)

        expect(new_award.url).to eq(custom_emoji.url)
      end
    end
  end

  describe '#to_ability_name' do
    let(:merge_request) { create(:merge_request) }
    let(:award_emoji) { build(:award_emoji, user: user, awardable: merge_request) }

    it 'returns correct ability name' do
      expect(award_emoji.to_ability_name).to be('emoji')
    end
  end
end
