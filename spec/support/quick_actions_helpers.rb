module QuickActionsHelpers
  def write_note(text)
    Sidekiq::Testing.fake! do
      page.within('.js-main-target-form') do
        fill_in 'note-body', with: text
        find('.js-comment-submit-button').trigger('click')
        wait_for_requests
      end
    end
  end
end
