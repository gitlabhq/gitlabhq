# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/accounts/show', feature_category: :user_profile do
  let_it_be(:user) { build_stubbed(:user) }

  before do
    assign(:user, user)
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'for account deletion' do
    context 'when user can delete profile' do
      before do
        allow(user).to receive(:can_be_removed?).and_return(true)
        allow(view)
          .to receive(:can?)
          .with(user, :destroy_user, user)
          .and_return(true)

        render
      end

      it 'renders delete button' do
        expect(rendered).to have_css("[data-testid='delete-account-button']")
      end
    end

    context 'when user does not have permissions to delete their own profile' do
      before do
        allow(user).to receive(:can_be_removed?).and_return(true)
        allow(view)
          .to receive(:can?)
          .with(user, :destroy_user, user)
          .and_return(false)

        render
      end

      it 'does not render delete button' do
        expect(rendered).not_to have_css("[data-testid='delete-account-button']")
      end

      it 'renders correct help text' do
        expect(rendered).to have_text("You don't have access to delete this user.")
      end
    end

    context 'when user cannot be verified automatically' do
      before do
        allow(user).to receive_messages(can_be_removed?: true, can_remove_self?: false)
        allow(view)
          .to receive(:can?)
          .with(user, :destroy_user, user)
          .and_return(false)

        render
      end

      it 'does not render delete button' do
        expect(rendered).not_to have_css("[data-testid='delete-account-button']")
      end

      it 'renders correct help text' do
        expect(rendered).to have_text('GitLab is unable to verify your identity automatically.')
      end
    end

    context 'when user has sole ownership of a group' do
      let_it_be(:group) { build_stubbed(:group) }

      before do
        allow(user).to receive_messages(can_be_removed?: false, solo_owned_groups: [group])
        allow(view)
          .to receive(:can?)
          .with(user, :destroy_user, user)
          .and_return(true)

        render
      end

      it 'does not render delete button' do
        expect(rendered).not_to have_css("[data-testid='delete-account-button']")
      end

      it 'renders correct help text' do
        expect(rendered).to have_text('Your account is currently the sole owner in the following:')
      end

      it 'renders group as a link in the list' do
        expect(rendered).to have_text('Groups')
        expect(rendered).to have_link(group.name, href: group.web_url)
      end
    end

    context 'when user has sole ownership of a organization' do
      let_it_be(:organization) { build_stubbed(:organization) }

      before do
        allow(user).to receive_messages(can_be_removed?: false, solo_owned_organizations: [organization])
        allow(view)
          .to receive(:can?)
          .with(user, :destroy_user, user)
          .and_return(true)
      end

      context 'when feature flag ui_for_organizations is false' do
        before do
          stub_feature_flags(ui_for_organizations: false)

          render
        end

        it 'does not render delete button' do
          expect(rendered).not_to have_css("[data-testid='delete-account-button']")
        end

        it 'renders correct help text' do
          expect(rendered).to have_text('Your account is currently the sole owner in the following:')
        end

        it 'does not render organization as a link in the list' do
          expect(rendered).not_to have_text('Organizations')
          expect(rendered).not_to have_link(organization.name, href: organization.web_url)
        end
      end

      context 'when feature flag ui_for_organizations is true' do
        before do
          stub_feature_flags(ui_for_organizations: true)

          render
        end

        it 'does not render delete button' do
          expect(rendered).not_to have_css("[data-testid='delete-account-button']")
        end

        it 'renders correct help text' do
          expect(rendered).to have_text('Your account is currently the sole owner in the following:')
        end

        it 'renders organization as a link in the list' do
          expect(rendered).to have_text('Organizations')
          expect(rendered).to have_link(organization.name, href: organization.web_url)
        end
      end
    end
  end

  context 'for owned pipeline schedules' do
    let(:test_id_selector) { '[data-testid="owned-scheduled-pipelines"]' }
    let(:active_schedules) { [] }

    before do
      render
    end

    it 'renders the section' do
      expect(rendered).to have_text('Scheduled pipelines you own')
    end

    it 'has no list' do
      expect(rendered).to have_text('You do not own any active scheduled pipelines')
      expect(rendered).to have_css("#{test_id_selector} ul li", count: 0)
    end

    context 'when active pipeline schedules are owned' do
      # rubocop:disable RSpec/FactoryBot/AvoidCreate -- we create records so that we can test the query performance.
      let_it_be(:active_schedules) do
        # To validate that two projects in the same group render as two
        # links.
        group = create(:group)
        project_1 = create(:project, :repository, group: group)
        project_2 = create(:project, :repository, group: group)
        [
          create(:ci_pipeline_schedule, project: project_1, owner: user),
          create(:ci_pipeline_schedule, project: project_2, owner: user),
          create(:ci_pipeline_schedule, owner: user)
        ]
      end
      # rubocop:enable RSpec/FactoryBot/AvoidCreate

      it 'renders the correct number of active pipeline schedules' do
        expect(rendered).to have_css("#{test_id_selector} ul li", count: 3)
      end

      it 'renders links to the project pipeline schedules page' do
        active_schedules.each do |schedule|
          expect(rendered).to have_link(
            href: project_pipeline_schedules_path(schedule.project)
          )
        end
      end

      it 'avoids N+1 queries', :request_store do
        # Firstly, record how many PostgreSQL queries the endpoint will
        # make when it returns the records created above.
        control = ActiveRecord::QueryRecorder.new { render }

        # Now create an additional scheduled pipeline record and ensure
        # that the API does not execute any more queries than before.
        create(:ci_pipeline_schedule, owner: user) # rubocop:disable RSpec/FactoryBot/AvoidCreate -- explained above

        expect { render }.not_to exceed_query_limit(control)
      end

      it 'handles orphaned schedules without errors' do
        orphaned_description = 'orphaned'
        non_existent_project_id = Project.maximum(:id).to_i + 1
        build_stubbed(
          :ci_pipeline_schedule,
          owner: user,
          description: orphaned_description,
          project_id: non_existent_project_id
        )

        expect { render }.not_to raise_error

        expect(rendered).to have_css("#{test_id_selector} ul li", count: 6)
        within(test_id_selector) do
          expect(rendered).not_to have_content(orphaned_description)
          expect(rendered).to have_content(active_schedules[0].description)
        end
      end
    end
  end
end
