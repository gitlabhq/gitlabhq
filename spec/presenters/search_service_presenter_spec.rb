# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchServicePresenter, feature_category: :global_search do
  let(:user) { create(:user) }
  let(:search) { '' }
  let(:search_service) { SearchService.new(user, search: search, scope: scope) }
  let(:presenter) { described_class.new(search_service, current_user: user) }

  describe '#search_objects' do
    let(:search_objects) { Kaminari::PaginatableArray.new([]) }

    context 'objects do not respond to eager_load' do
      before do
        allow(search_service).to receive(:search_objects).and_return(search_objects)
        allow(search_objects).to receive(:respond_to?).with(:eager_load).and_return(false)
      end

      context 'users scope' do
        let(:scope) { 'users' }

        it 'does not eager load anything' do
          expect(search_objects).not_to receive(:eager_load)
          presenter.search_objects
        end
      end
    end
  end

  describe '#show_results_status?' do
    using RSpec::Parameterized::TableSyntax

    let(:scope) { nil }

    before do
      allow(presenter).to receive(:search_objects).and_return([])
      allow(presenter).to receive(:without_count?).and_return(!with_count)
      allow(presenter).to receive(:show_snippets?).and_return(show_snippets)
      allow(presenter).to receive(:show_sort_dropdown?).and_return(show_sort_dropdown)
    end

    where(:with_count, :show_snippets, :show_sort_dropdown, :result) do
      true  | true  | true  | true
      false | true  | false | true
      false | false | true  | true
      false | false | false | false
    end

    with_them do
      it { expect(presenter.show_results_status?).to eq(result) }
    end
  end

  describe '#advanced_search_enabled?' do
    let(:scope) { nil }

    it { expect(presenter.advanced_search_enabled?).to eq(false) }
  end

  describe '#zoekt_enabled?' do
    let(:scope) { nil }

    it { expect(presenter.zoekt_enabled?).to eq(false) }
  end
end
