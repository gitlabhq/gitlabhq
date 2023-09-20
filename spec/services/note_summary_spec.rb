# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NoteSummary, feature_category: :code_review_workflow do
  let(:project)  { build(:project) }
  let(:noteable) { build(:issue) }
  let(:user)     { build(:user) }

  def create_note_summary
    described_class.new(noteable, project, user, 'note', action: 'icon', commit_count: 5)
  end

  describe '#metadata?' do
    it 'returns true when metadata present' do
      expect(create_note_summary.metadata?).to be_truthy
    end

    it 'returns false when metadata not present' do
      expect(described_class.new(noteable, project, user, 'note').metadata?).to be_falsey
    end
  end

  describe '#note' do
    it 'returns note hash' do
      freeze_time do
        expect(create_note_summary.note).to eq(
          noteable: noteable,
          project: project,
          author: user,
          note: 'note',
          created_at: Time.current
        )
      end
    end

    context 'when noteable is a commit' do
      let(:noteable) { build(:commit, system_note_timestamp: Time.zone.at(43)) }

      it 'returns note hash specific to commit' do
        expect(create_note_summary.note).to eq(
          noteable: nil, project: project, author: user, note: 'note',
          noteable_type: 'Commit', commit_id: noteable.id,
          created_at: Time.zone.at(43)
        )
      end
    end
  end

  describe '#metadata' do
    it 'returns metadata hash' do
      expect(create_note_summary.metadata).to eq(action: 'icon', commit_count: 5)
    end

    context 'description action and noteable has saved_description_version' do
      before do
        noteable.saved_description_version = 1
      end

      subject { described_class.new(noteable, project, user, 'note', action: 'description') }

      it 'sets the description_version metadata' do
        expect(subject.metadata).to include(description_version: 1)
      end
    end
  end
end
