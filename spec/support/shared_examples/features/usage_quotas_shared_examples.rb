# frozen_string_literal: true

RSpec.shared_examples 'Usage Quotas is accessible' do
  context 'when on a page that has access to Usage Quotas' do
    it 'is linked from the sidebar in a top-level group' do
      within_testid('super-sidebar') do
        expect(page).to have_link('Usage Quotas', href: usage_quotas_path)
      end
    end

    it 'opens the Usage Quotas page' do
      within_testid('super-sidebar') do
        click_link('Usage Quotas')
      end

      expect(find_by_testid('page-heading')).to have_text('Usage Quotas')
    end
  end
end
