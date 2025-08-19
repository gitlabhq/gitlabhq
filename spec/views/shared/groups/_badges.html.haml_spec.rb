# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/groups/_badges.html.haml', feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { build(:group) }

  describe 'badge rendering based on group status' do
    where :deletion_in_progress, :scheduled_for_deletion, :archived, :expected_badge, :expected_text do
      true  | true  | true  | '.badge-warning' | _('Deletion in progress')
      true  | true  | false | '.badge-warning' | _('Deletion in progress')
      true  | false | true  | '.badge-warning' | _('Deletion in progress')
      true  | false | false | '.badge-warning' | _('Deletion in progress')
      false | true  | true  | '.badge-warning' | _('Pending deletion')
      false | true  | false | '.badge-warning' | _('Pending deletion')
      false | false | true  | '.badge-info'    | _('Archived')
      false | false | false | nil              | nil
    end

    with_them do
      before do
        allow(group).to receive_messages(
          scheduled_for_deletion_in_hierarchy_chain?: scheduled_for_deletion,
          self_deletion_in_progress?: deletion_in_progress,
          self_or_ancestors_archived?: archived
        )
      end

      it 'renders the appropriate badge or no badge' do
        render 'shared/groups/badges', group: group

        if expected_badge
          expect(rendered).to have_css(expected_badge, text: expected_text)
        else
          expect(rendered).to be_empty
        end
      end
    end
  end
end
