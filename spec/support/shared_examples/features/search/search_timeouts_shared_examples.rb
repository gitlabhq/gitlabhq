# frozen_string_literal: true

RSpec.shared_examples 'search timeouts' do |scope|
  let(:additional_params) { {} }

  context 'when search times out' do
    before do
      allow_next_instance_of(SearchService) do |service|
        allow(service).to receive(:search_results).and_raise(ActiveRecord::QueryCanceled)
      end

      visit(search_path(search: 'test', scope: scope, **additional_params))
    end

    it 'renders timeout information' do
      expect(page).to have_content('Your search has timed out')
    end
  end

  # In the new work_item epic there are no counts as of yet, so we need to stub the feature flag
  context 'when search times out and feature flag is off' do
    before do
      stub_feature_flags(work_item_scope_frontend: false)

      allow_next_instance_of(SearchService) do |service|
        allow(service).to receive(:search_results).and_raise(ActiveRecord::QueryCanceled)
      end

      visit(search_path(search: 'test', scope: scope, **additional_params))
    end

    it 'sets tab count to 0' do
      expect(page.find('[data-testid="search-filter"] [aria-current="page"]')).to have_text('0')
    end
  end
end
