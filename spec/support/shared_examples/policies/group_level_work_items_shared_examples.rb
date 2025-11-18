# frozen_string_literal: true

RSpec.shared_examples 'abilities without group level work items license' do
  context 'without group level work items license' do
    before do
      stub_licensed_features(epics: false)
    end

    it 'checks non-member abilities' do
      expect(permissions(non_member_user, work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji
      )
      expect(permissions(non_member_user, confidential_work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji,
        :move_work_item, :clone_work_item
      )
    end

    it 'checks project guest abilities' do
      expect(permissions(guest, not_persisted_work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji,
        :move_work_item, :clone_work_item
      )
      expect(permissions(guest, work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji,
        :move_work_item, :clone_work_item
      )
      expect(permissions(guest, confidential_work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji,
        :move_work_item, :clone_work_item
      )
    end

    it 'checks project planner abilities' do
      expect(permissions(planner, work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji
      )
      expect(permissions(planner, confidential_work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji,
        :move_work_item, :clone_work_item
      )
    end

    it 'checks project reporter abilities' do
      expect(permissions(reporter, work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji,
        :move_work_item, :clone_work_item
      )
      expect(permissions(reporter, confidential_work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji,
        :move_work_item, :clone_work_item
      )
    end

    it 'checks group guest abilities' do
      expect(permissions(group_guest, work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji,
        :move_work_item, :clone_work_item
      )
      expect(permissions(group_guest, confidential_work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji,
        :move_work_item, :clone_work_item
      )
      expect(permissions(group_guest_author, authored_work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji,
        :move_work_item, :clone_work_item
      )
      expect(permissions(group_guest_author, authored_confidential_work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji,
        :move_work_item, :clone_work_item
      )
    end

    it 'checks group planner abilities' do
      expect(permissions(group_planner, work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji,
        :move_work_item, :clone_work_item
      )
      expect(permissions(group_planner, confidential_work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji,
        :move_work_item, :clone_work_item
      )
    end

    it 'checks group reporter abilities' do
      expect(permissions(group_reporter, work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji,
        :move_work_item, :clone_work_item
      )
      expect(permissions(group_reporter, confidential_work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji,
        :move_work_item, :clone_work_item
      )
    end
  end
end

RSpec.shared_examples 'abilities with group level work items license' do
  context 'with group level work items license', if: Gitlab.ee? do
    before do
      stub_licensed_features(epics: true)
    end

    it 'checks project guest abilities' do
      expect(permissions(guest, not_persisted_work_item)).to be_allowed(
        :read_work_item, :read_issue, :read_note, :create_note, :award_emoji)
      expect(permissions(guest, work_item)).to be_allowed(
        :read_work_item, :read_issue, :read_note, :create_note, :award_emoji)

      expect(permissions(guest, not_persisted_work_item)).to be_disallowed(
        :admin_work_item, :update_work_item, :delete_work_item, :admin_parent_link, :set_work_item_metadata,
        :admin_work_item_link, :move_work_item, :clone_work_item
      )
      expect(permissions(guest, work_item)).to be_disallowed(
        :admin_work_item, :update_work_item, :delete_work_item, :admin_parent_link, :set_work_item_metadata,
        :admin_work_item_link, :move_work_item, :clone_work_item
      )
      expect(permissions(guest, confidential_work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :admin_parent_link,
        :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji, :move_work_item, :clone_work_item
      )
    end

    it 'checks project planner abilities' do
      expect(permissions(planner, work_item)).to be_allowed(
        :read_work_item, :read_issue, :read_note, :create_note, :award_emoji
      )

      expect(permissions(planner, work_item)).to be_disallowed(
        :admin_work_item, :update_work_item, :delete_work_item, :admin_parent_link, :set_work_item_metadata,
        :admin_work_item_link, :move_work_item, :clone_work_item
      )
      expect(permissions(planner, confidential_work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :admin_parent_link,
        :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji, :move_work_item, :clone_work_item
      )
    end

    it 'checks project reporter abilities' do
      expect(permissions(reporter, work_item)).to be_allowed(
        :read_work_item, :read_issue, :read_note, :create_note, :award_emoji
      )

      expect(permissions(reporter, work_item)).to be_disallowed(
        :admin_work_item, :update_work_item, :delete_work_item, :admin_parent_link, :set_work_item_metadata,
        :admin_work_item_link, :move_work_item, :clone_work_item
      )
      expect(permissions(reporter, confidential_work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :admin_parent_link,
        :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji, :move_work_item, :clone_work_item
      )
    end

    it 'checks group guest abilities' do
      expect(permissions(group_guest, not_persisted_work_item)).to be_allowed(
        :read_work_item, :read_issue, :read_note, :admin_parent_link, :set_work_item_metadata, :admin_work_item_link,
        :create_note, :award_emoji
      )
      expect(permissions(group_guest, work_item)).to be_allowed(
        :read_work_item, :read_issue, :read_note, :admin_parent_link, :admin_work_item_link, :create_note, :award_emoji
      )
      expect(permissions(group_guest_author, authored_work_item)).to be_allowed(
        :read_work_item, :read_issue, :read_note, :update_work_item, :delete_work_item, :admin_parent_link,
        :admin_work_item_link, :create_note, :award_emoji
      )
      expect(permissions(group_guest_author, authored_confidential_work_item)).to be_allowed(
        :read_work_item, :read_issue, :read_note, :update_work_item, :delete_work_item, :admin_parent_link,
        :admin_work_item_link, :create_note, :award_emoji
      )

      expect(permissions(group_guest, work_item)).to be_disallowed(
        :admin_work_item, :update_work_item, :delete_work_item, :set_work_item_metadata,
        :move_work_item, :clone_work_item
      )
      expect(permissions(group_guest, confidential_work_item)).to be_disallowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
        :set_work_item_metadata, :create_note, :award_emoji, :move_work_item, :clone_work_item
      )
      expect(permissions(group_guest_author, authored_work_item)).to be_disallowed(
        :admin_work_item, :set_work_item_metadata, :move_work_item, :clone_work_item
      )
      expect(permissions(group_guest_author, authored_confidential_work_item)).to be_disallowed(
        :admin_work_item, :set_work_item_metadata, :move_work_item, :clone_work_item
      )
    end

    it 'checks group planner abilities' do
      expect(permissions(group_planner, work_item)).to be_allowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :admin_parent_link,
        :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji, :move_work_item, :clone_work_item
      )
      expect(permissions(group_planner, confidential_work_item)).to be_allowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :admin_parent_link,
        :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji, :move_work_item, :clone_work_item
      )

      expect(permissions(group_planner, work_item)).to be_allowed(:delete_work_item)
      expect(permissions(group_planner, confidential_work_item)).to be_allowed(:delete_work_item)
    end

    it 'checks group reporter abilities' do
      expect(permissions(group_reporter, work_item)).to be_allowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :admin_parent_link,
        :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji, :move_work_item, :clone_work_item
      )
      expect(permissions(group_reporter, confidential_work_item)).to be_allowed(
        :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :admin_parent_link,
        :set_work_item_metadata, :admin_work_item_link, :create_note, :award_emoji, :move_work_item, :clone_work_item
      )

      expect(permissions(group_reporter, work_item)).to be_disallowed(:delete_work_item)
      expect(permissions(group_reporter, confidential_work_item)).to be_disallowed(:delete_work_item)
    end
  end
end
