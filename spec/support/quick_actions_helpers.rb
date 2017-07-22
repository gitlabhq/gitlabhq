module QuickActionsHelpers
  def write_note(text, wait = true)
    Sidekiq::Testing.fake! do
      page.within('.js-main-target-form') do
        fill_in 'note[note]', with: text
        find('.js-comment-submit-button').trigger('click')

        if wait
          wait_for_requests
        end
      end
    end
  end
end
