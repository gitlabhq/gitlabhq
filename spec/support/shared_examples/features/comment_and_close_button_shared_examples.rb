# frozen_string_literal: true

RSpec.shared_examples 'page with comment and close button' do |button_text|
  context 'when remove_comment_close_reopen feature flag is enabled' do
    before do
      stub_feature_flags(remove_comment_close_reopen: true)
      setup
    end

    it "does not show #{button_text} button" do
      within '.note-form-actions' do
        expect(page).not_to have_button(button_text)
      end
    end
  end

  context 'when remove_comment_close_reopen feature flag is disabled' do
    before do
      stub_feature_flags(remove_comment_close_reopen: false)
      setup
    end

    it "shows #{button_text} button" do
      within '.note-form-actions' do
        expect(page).to have_button(button_text)
      end
    end
  end
end
