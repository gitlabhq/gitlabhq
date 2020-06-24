# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixPromotedEpicsDiscussionIds, schema: 20190715193142 do
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:epics) { table(:epics) }
  let(:notes) { table(:notes) }

  let(:user) { users.create!(email: 'test@example.com', projects_limit: 100, username: 'test') }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:epic1) { epics.create!(id: 1, author_id: user.id, iid: 1, group_id: namespace.id, title: 'Epic with discussion', title_html: 'Epic with discussion') }

  def create_note(discussion_id)
    notes.create!(note: 'note comment',
                  noteable_id: epic1.id,
                  noteable_type: 'Epic',
                  discussion_id: discussion_id)
  end

  def expect_valid_discussion_id(id)
    expect(id).to match(/\A\h{40}\z/)
  end

  describe '#perform with batch of discussion ids' do
    it 'updates discussion ids' do
      note1 = create_note('00000000')
      note2 = create_note('00000000')
      note3 = create_note('10000000')

      subject.perform(%w(00000000 10000000))

      expect_valid_discussion_id(note1.reload.discussion_id)
      expect_valid_discussion_id(note2.reload.discussion_id)
      expect_valid_discussion_id(note3.reload.discussion_id)
      expect(note1.discussion_id).to eq(note2.discussion_id)
      expect(note1.discussion_id).not_to eq(note3.discussion_id)
    end

    it 'skips notes with discussion id not in range' do
      note4 = create_note('20000000')

      subject.perform(%w(00000000 10000000))

      expect(note4.reload.discussion_id).to eq('20000000')
    end
  end
end
