# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/groups/_badges.html.haml', feature_category: :groups_and_projects do
  let(:group) { build(:group) }
  let(:self_deletion_in_progress) { false }

  before do
    allow(group).to receive_messages(
      deletion_in_progress_or_scheduled_in_hierarchy_chain?: deletion_in_progress_or_scheduled_in_hierarchy_chain,
      self_deletion_in_progress?: self_deletion_in_progress
    )
  end

  context 'when the group is not in a deletion state' do
    let(:deletion_in_progress_or_scheduled_in_hierarchy_chain) { false }

    it 'does not render the badge' do
      output = view.render('shared/groups/badges', group: group)

      expect(output).to be_nil
    end
  end

  context 'when the group is in a deletion state' do
    let(:deletion_in_progress_or_scheduled_in_hierarchy_chain) { true }

    context 'when the deletion is in progress' do
      let(:self_deletion_in_progress) { true }

      it 'renders the badge' do
        render 'shared/groups/badges', group: group

        expect(rendered).to have_css('.badge-warning', text: 'Deletion in progress')
      end
    end

    context 'when the deletion is scheduled' do
      let(:self_deletion_in_progress) { false }

      it 'renders the badge' do
        render 'shared/groups/badges', group: group

        expect(rendered).to have_css('.badge-warning', text: 'Pending deletion')
      end
    end
  end
end
