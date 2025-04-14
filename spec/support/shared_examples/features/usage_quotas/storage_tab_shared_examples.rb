# frozen_string_literal: true

RSpec.shared_examples 'namespace Usage Quotas > Storage tab' do
  context 'when directly accessed via a url' do
    before do
      visit storage_tab_url
    end

    it 'displays the overview cards header' do
      expect(find_by_testid('overview-subtitle')).to have_text('Namespace overview')
    end

    it 'displays the namespace overview card' do
      within_testid 'namespace-usage-total-content' do
        expect(page).to have_text(namespace_storage_size_used_text)
      end
    end
  end
end
