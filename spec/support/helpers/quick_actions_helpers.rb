module QuickActionsHelpers
  def write_note(text)
    Sidekiq::Testing.fake! do
      page.within('.js-main-target-form') do
        fill_in 'note[note]', with: text
        find('.js-comment-submit-button').click
      end
    end
  end
end
