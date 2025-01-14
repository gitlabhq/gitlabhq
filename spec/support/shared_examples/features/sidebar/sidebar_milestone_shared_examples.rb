# frozen_string_literal: true

RSpec.shared_examples 'milestone sidebar widget' do
  context 'editing milestone' do
    # Ensure support bot user is created so creation doesn't count towards query limit
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
    let_it_be(:support_bot) { Users::Internal.support_bot }
    let_it_be(:milestone_expired) { create(:milestone, project: project, title: 'Foo - expired', due_date: 5.days.ago) }
    let_it_be(:milestone_no_duedate) { create(:milestone, project: project, title: 'Foo - No due date') }
    let_it_be(:milestone1) { create(:milestone, project: project, title: 'Milestone-1', due_date: 20.days.from_now) }
    let_it_be(:milestone2) { create(:milestone, project: project, title: 'Milestone-2', due_date: 15.days.from_now) }
    let_it_be(:milestone3) { create(:milestone, project: project, title: 'Milestone-3', due_date: 10.days.from_now) }

    let(:milestone_widget) { find('[data-testid="sidebar-milestones"]') }

    before do
      within(milestone_widget) do
        click_button 'Edit'
      end

      wait_for_all_requests
    end

    it 'shows milestones list in the dropdown' do
      # 5 milestones + "No milestone" = 6 items
      expect(milestone_widget.find('.gl-dropdown-contents')).to have_selector('li.gl-dropdown-item', count: 6)
    end

    it 'shows expired milestone at the bottom of the list and milestone due earliest at the top of the list',
      :aggregate_failures do
      within(milestone_widget, '.gl-dropdown-contents') do
        expect(page.find('li:last-child')).to have_content milestone_expired.title

        [milestone3, milestone2, milestone1, milestone_no_duedate].each_with_index do |m, i|
          expect(page.all('li.gl-dropdown-item')[i + 1]).to have_content m.title
        end
      end
    end

    it 'adds a milestone' do
      within(milestone_widget) do
        click_button milestone1.title

        wait_for_requests

        page.within('[data-testid="select-milestone"]') do
          expect(page).to have_content(milestone1.title)
        end
      end
    end

    it 'removes a milestone' do
      within(milestone_widget) do
        click_button "No milestone"

        wait_for_requests

        page.within('[data-testid="select-milestone"]') do
          expect(page).not_to have_content(milestone1.title)
        end
      end
    end
  end
end
