# frozen_string_literal: true

RSpec.shared_examples 'search timeouts' do |scope|
  context 'when search times out' do
    before do
      allow_next_instance_of(SearchService) do |service|
        allow(service).to receive(:search_objects).and_raise(ActiveRecord::QueryCanceled)
      end

      visit(search_path(search: 'test', scope: scope))
    end

    it 'renders timeout information' do
      expect(page).to have_content('Your search timed out')
    end

    it 'sets tab count to 0' do
      expect(page.find('.search-filter .active')).to have_text('0')
    end
  end
end
