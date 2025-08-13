# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/projects/_badges.html.haml', feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { build(:project) }

  describe 'badge rendering based on project status' do
    where(:scheduled_for_deletion, :show_archived_badge, :expected_badge_class, :expected_badge_text) do
      true  | true  | '.badge-warning' | 'Pending deletion'
      true  | false | '.badge-warning' | 'Pending deletion'
      false | true  | '.badge-info'    | 'Archived'
      false | false | nil              | nil
    end

    with_them do
      before do
        allow(view).to receive(:show_archived_badge?).with(project).and_return(show_archived_badge)
        allow(project)
          .to receive(:scheduled_for_deletion_in_hierarchy_chain?).and_return(scheduled_for_deletion)
      end

      it 'renders the appropriate badge or no badge' do
        render 'shared/projects/badges', project: project

        if expected_badge_class
          expect(rendered).to have_css(expected_badge_class, text: expected_badge_text)
        else
          expect(rendered).to be_blank
        end
      end
    end
  end
end
