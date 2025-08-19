# frozen_string_literal: true

RSpec.shared_examples 'Usage quotas is accessible' do
  context 'when on a page that has access to Usage quotas' do
    it 'is linked from the sidebar in a top-level group' do
      within_testid('super-sidebar') do
        expect(page).to have_link('Usage quotas', href: usage_quotas_path)
      end
    end

    it 'opens the Usage quotas page' do
      within_testid('super-sidebar') do
        click_link('Usage quotas')
      end

      expect(find_by_testid('page-heading')).to have_text('Usage quotas')
    end
  end
end
