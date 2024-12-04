# frozen_string_literal: true

RSpec.shared_examples 'shows and resets runner registration token' do
  include Features::RunnersHelpers
  include Spec::Support::Helpers::ModalHelpers

  it 'shows registration instructions' do
    click_on dropdown_text
    click_on 'Show runner installation and registration instructions'

    within_modal do
      expect(page).to have_text "Install a runner"
      expect(page).to have_text "Environment"
      expect(page).to have_text "Architecture"
      expect(page).to have_text "Download and install binary"
    end
  end

  it 'resets current registration token' do
    click_on dropdown_text
    click_on 'Click to reveal'

    # current registration token
    expect(page.find_field('token-value').value).to eq(registration_token)

    # reset registration token
    click_on 'Reset registration token'
    within_modal do
      click_button('Reset token', match: :first)
    end

    # new registration token
    click_on dropdown_text
    expect(find_field('token-value').value).not_to eq(registration_token)
    expect(find('.gl-toast')).to have_content('New registration token generated!')
  end
end

RSpec.shared_examples 'shows no runners registered' do
  it 'shows 0 count and the empty state' do
    expect(find('[data-testid="runner-type-tabs"]')).to have_text "All 0"

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

RSpec.shared_examples 'shows runner summary and navigates to details' do
  it 'shows runner summary and details' do
    expect(page).not_to have_content s_('Runners|Get started with runners')

    # see runner summary in list
    within_runner_row(runner.id) do
      expect(page).to have_text "##{runner.id}"
      expect(page).to have_text runner.short_sha
      expect(page).to have_text runner.description
    end

    # navigate to see runner details
    click_link("##{runner.id} (#{runner.short_sha})")
    expect(current_url).to include(runner_page_path)

    expect(page).to have_selector 'h1', text: "##{runner.id} (#{runner.short_sha})"
    expect(page).to have_content "#{s_('Runners|Description')} #{runner.description}"
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

    it 'confirms runner deletion' do
      expect(page).to have_text "Delete runner ##{runner.id} (#{runner.short_sha})?"
      expect(page).to have_text "Are you sure you want to continue?"

      within_modal do
        click_on 'Permanently delete runner'
      end

      expect(page.find('.gl-toast')).to have_text(/Runner .+ deleted/)
      expect(page).not_to have_content runner.description
    end

    it 'cancels runner deletion' do
      within_modal do
        click_on 'Cancel'
      end

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
  it 'show jobs in tab' do
    click_on("#{s_('Runners|Jobs')} #{job_count}")

    within "[data-testid='job-row-#{job.id}']" do
      expect(page).to have_link("##{job.id}")
    end
  end
end

RSpec.shared_examples 'shows locked field' do
  it 'shows locked checkbox with description', :js do
    expect(page).to have_selector('input[type="checkbox"][name="locked"]')
    expect(page).to have_content(_('Lock to current projects'))
  end
end

RSpec.shared_examples 'submits edit runner form' do
  it 'breadcrumb contains runner id and token', :js do
    within_testid 'breadcrumb-links' do
      expect(page).to have_link("##{runner.id} (#{runner.short_sha})")
      expect(find('li:last-of-type')).to have_content("Edit")
    end
  end

  context 'when a runner is updated', :js do
    before do
      fill_in s_('Runners|Runner description'), with: 'new-runner-description', fill_options: { clear: :backspace }

      click_on _('Save changes')
    end

    it 'redirects to runner page and shows successful update' do
      expect(current_url).to match(runner_page_path)

      expect(page.find('[data-testid="alert-success"]')).to have_content('saved')
      expect(page).to have_content("#{s_('Runners|Description')} new-runner-description")
    end
  end
end

RSpec.shared_examples 'creates runner and shows register page' do
  context 'when runner is saved' do
    before do
      fill_in s_('Runners|Runner description'), with: 'runner-foo'
      fill_in s_('Runners|Tags'), with: 'tag1'
      click_on s_('Runners|Create runner')
    end

    it 'navigates to registration page and opens install instructions drawer' do
      expect(page.find('[data-testid="alert-success"]')).to have_content(s_('Runners|Runner created.'))
      expect(current_url).to match(register_path_pattern)

      click_on 'How do I install GitLab Runner?'
      expect(page.find('[data-testid="runner-platforms-drawer"]')).to have_content('gitlab-runner install')
    end

    it 'warns from leaving page without finishing registration' do
      click_on s_('Runners|View runners')

      alert = page.driver.browser.switch_to.alert

      expect(alert).not_to be_nil
      alert.dismiss

      expect(current_url).to match(register_path_pattern)
    end
  end
end
