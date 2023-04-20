# frozen_string_literal: true

RSpec.shared_examples 'shows and resets runner registration token' do
  include Features::RunnersHelpers
  include Spec::Support::Helpers::ModalHelpers

  before do
    click_on dropdown_text
  end

  describe 'shows registration instructions' do
    before do
      click_on 'Show runner installation and registration instructions'

      wait_for_requests
    end

    it 'opens runner installation modal', :aggregate_failures do
      within_modal do
        expect(page).to have_text "Install a runner"
        expect(page).to have_text "Environment"
        expect(page).to have_text "Architecture"
        expect(page).to have_text "Download and install binary"
      end
    end

    it 'dismisses runner installation modal' do
      within_modal do
        click_button('Close', match: :first)
      end

      expect(page).not_to have_text "Install a runner"
    end
  end

  it 'has a registration token' do
    click_on 'Click to reveal'
    expect(page.find_field('token-value').value).to have_content(registration_token)
  end

  describe 'reset registration token' do
    let!(:old_registration_token) { find_field('token-value').value }

    before do
      click_on 'Reset registration token'

      within_modal do
        click_button('Reset token', match: :first)
      end

      wait_for_requests
    end

    it 'changes registration token' do
      expect(find('.gl-toast')).to have_content('New registration token generated!')

      click_on dropdown_text
      click_on 'Click to reveal'

      expect(old_registration_token).not_to eq registration_token
    end
  end
end

RSpec.shared_examples 'shows no runners registered' do
  it 'shows 0 count and the empty state' do
    expect(find('[data-testid="runner-type-tabs"]')).to have_text "#{s_('Runners|All')} 0"

    # No stats are shown
    expect(page).not_to have_text s_('Runners|Online')
    expect(page).not_to have_text s_('Runners|Offline')
    expect(page).not_to have_text s_('Runners|Stale')

    # "no runners" message
    expect(page).to have_text s_('Runners|Get started with runners')
  end
end

RSpec.shared_examples 'shows no runners found' do
  it 'shows "no runners" message' do
    expect(page).to have_text s_('Runners|No results found')
  end
end

RSpec.shared_examples 'shows runner in list' do
  it 'shows runner row and no empty state' do
    within_runner_row(runner.id) do
      expect(page).to have_text "##{runner.id}"
      expect(page).to have_text runner.short_sha
      expect(page).to have_text runner.description
    end

    expect(page).not_to have_content s_('Runners|Get started with runners')
  end
end

RSpec.shared_examples 'pauses, resumes and deletes a runner' do
  include Spec::Support::Helpers::ModalHelpers

  it 'pauses and resumes runner' do
    within_runner_row(runner.id) do
      click_button "Pause"

      expect(page).to have_text s_('Runners|Paused')
      expect(page).to have_button 'Resume'
      expect(page).not_to have_button 'Pause'

      click_button "Resume"

      expect(page).not_to have_text 'paused'
      expect(page).not_to have_button 'Resume'
      expect(page).to have_button 'Pause'
    end
  end

  describe 'deletes runner' do
    before do
      within_runner_row(runner.id) do
        click_on 'Delete runner'
      end
    end

    it 'shows a confirmation modal' do
      expect(page).to have_text "Delete runner ##{runner.id} (#{runner.short_sha})?"
      expect(page).to have_text "Are you sure you want to continue?"
    end

    it 'deletes a runner' do
      within_modal do
        click_on 'Delete runner'
      end

      expect(page.find('.gl-toast')).to have_text(/Runner .+ deleted/)
      expect(page).not_to have_content runner.description
    end

    it 'cancels runner deletion' do
      within_modal do
        click_on 'Cancel'
      end

      wait_for_requests

      expect(page).to have_content runner.description
    end
  end
end

RSpec.shared_examples 'deletes runners in bulk' do
  describe 'when selecting all for deletion', :js do
    before do
      check s_('Runners|Select all')
      click_button s_('Runners|Delete selected')

      within_modal do
        click_on "Permanently delete #{runner_count} runners"
      end

      wait_for_requests
    end

    it_behaves_like 'shows no runners registered'
  end
end

RSpec.shared_examples 'filters by tag' do
  it 'shows correct runner when tag matches' do
    expect(page).to have_content found_runner
    expect(page).to have_content missing_runner

    input_filtered_search_filter_is_only('Tags', tag)

    expect(page).to have_content found_runner
    expect(page).not_to have_content missing_runner
  end
end

RSpec.shared_examples 'shows runner jobs tab' do
  context 'when clicking on jobs tab' do
    before do
      click_on("#{s_('Runners|Jobs')} #{job_count}")

      wait_for_requests
    end

    it 'shows job in list' do
      within "[data-testid='job-row-#{job.id}']" do
        expect(page).to have_link("##{job.id}")
      end
    end
  end
end

RSpec.shared_examples 'submits edit runner form' do
  it 'breadcrumb contains runner id and token' do
    page.within '[data-testid="breadcrumb-links"]' do
      expect(page).to have_link("##{runner.id} (#{runner.short_sha})")
      expect(page.find('[data-testid="breadcrumb-current-link"]')).to have_content("Edit")
    end
  end

  describe 'runner header', :js do
    it 'contains the runner id' do
      expect(page).to have_content("Runner ##{runner.id} created")
    end
  end

  context 'when a runner is updated', :js do
    before do
      find('[data-testid="runner-field-description"] input').set('new-runner-description')

      click_on _('Save changes')
      wait_for_requests
    end

    it 'redirects to runner page' do
      expect(current_url).to match(runner_page_path)
    end

    it 'show success alert' do
      expect(page.find('[data-testid="alert-success"]')).to have_content('saved')
    end

    it 'shows updated information' do
      expect(page).to have_content("#{s_('Runners|Description')} new-runner-description")
    end
  end
end

RSpec.shared_examples 'creates runner and shows register page' do
  context 'when runner is saved' do
    before do
      fill_in s_('Runners|Runner description'), with: 'runner-foo'
      fill_in s_('Runners|Tags'), with: 'tag1'
      click_on _('Submit')
      wait_for_requests
    end

    it 'navigates to registration page and opens install instructions drawer' do
      expect(page.find('[data-testid="alert-success"]')).to have_content(s_('Runners|Runner created.'))
      expect(current_url).to match(register_path_pattern)

      click_on 'How do I install GitLab Runner?'
      expect(page.find('[data-testid="runner-platforms-drawer"]')).to have_content('gitlab-runner install')
    end

    it 'warns from leaving page without finishing registration' do
      click_on s_('Runners|Go to runners page')

      alert = page.driver.browser.switch_to.alert

      expect(alert).not_to be_nil
      alert.dismiss

      expect(current_url).to match(register_path_pattern)
    end
  end
end
