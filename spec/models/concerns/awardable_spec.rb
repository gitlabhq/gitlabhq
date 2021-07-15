# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Awardable do
  let!(:note) { create(:note) }
  let!(:award_emoji) { create(:award_emoji, :downvote, awardable: note) }

  describe "Associations" do
    subject { build(:note) }

    it { is_expected.to have_many(:award_emoji).dependent(:destroy) }
  end

  describe "ClassMethods" do
    let!(:note2) { create(:note) }
    let!(:award_emoji2) { create(:award_emoji, awardable: note2) }

    describe "orders" do
      it "orders on upvotes" do
        expect(Note.order_upvotes_desc.to_a).to eq [note2, note]
      end

      it "orders on downvotes" do
        expect(Note.order_downvotes_desc.to_a).to eq [note, note2]
      end
    end

    describe "#awarded" do
      it "filters by user and emoji name" do
        expect(Note.awarded(award_emoji.user, "thumbsup")).to be_empty
        expect(Note.awarded(award_emoji.user, "thumbsdown")).to eq [note]
        expect(Note.awarded(award_emoji2.user, "thumbsup")).to eq [note2]
        expect(Note.awarded(award_emoji2.user, "thumbsdown")).to be_empty
      end

      it "filters by user and any emoji" do
        note3 = create(:note)
        create(:award_emoji, awardable: note3, name: "star", user: award_emoji.user)
        create(:award_emoji, awardable: note3, name: "star", user: award_emoji2.user)

        expect(Note.awarded(award_emoji.user)).to contain_exactly(note, note3)
        expect(Note.awarded(award_emoji2.user)).to contain_exactly(note2, note3)
      end
    end

    describe "#not_awarded" do
      it "returns notes not awarded by user" do
        expect(Note.not_awarded(award_emoji.user)).to eq [note2]
        expect(Note.not_awarded(award_emoji2.user)).to eq [note]
      end
    end
  end

  describe "#upvotes" do
    it "counts the number of upvotes" do
      expect(note.upvotes).to be 0
    end
  end

  describe "#downvotes" do
    it "counts the number of downvotes" do
      expect(note.downvotes).to be 1
    end
  end

  describe '#user_can_award?' do
    let(:user) { create(:user) }

    before do
      note.project.add_guest(user)
    end

    it 'is truthy when the user is allowed to award emoji' do
      expect(note.user_can_award?(user)).to be_truthy
    end

    it 'is falsy when the project is archived' do
      note.project.update!(archived: true)

      expect(note.user_can_award?(user)).to be_falsy
    end
  end

  describe 'querying award_emoji on an Awardable' do
    let(:note) { create(:note) }

    it 'sorts in ascending fashion' do
      create_list(:award_emoji, 3, awardable: note)

      expect(note.award_emoji).to eq note.award_emoji.sort_by(&:id)
    end
  end

  describe "#grouped_awards" do
    context 'default award emojis' do
      let(:note_without_downvote) { create(:note) }
      let(:note_with_downvote) do
        note_with_downvote = create(:note)
        create(:award_emoji, :downvote, awardable: note_with_downvote)
        note_with_downvote
      end

      it "includes unused thumbs buttons by default" do
        expect(note_without_downvote.grouped_awards.keys.sort).to eq %w(thumbsdown thumbsup)
      end

      it "doesn't include unused thumbs buttons when disabled in project" do
        note_without_downvote.project.show_default_award_emojis = false

        expect(note_without_downvote.grouped_awards.keys.sort).to be_empty
      end

      it "includes unused thumbs buttons when enabled in project" do
        note_without_downvote.project.show_default_award_emojis = true

        expect(note_without_downvote.grouped_awards.keys.sort).to eq %w(thumbsdown thumbsup)
      end

      it "doesn't include unused thumbs buttons in summary" do
        expect(note_without_downvote.grouped_awards(with_thumbs: false).keys).to be_empty
      end

      it "includes used thumbs buttons when disabled in project" do
        note_with_downvote.project.show_default_award_emojis = false

        expect(note_with_downvote.grouped_awards.keys).to eq %w(thumbsdown)
      end

      it "includes used thumbs buttons in summary" do
        expect(note_with_downvote.grouped_awards(with_thumbs: false).keys).to eq %w(thumbsdown)
      end
    end
  end
end
