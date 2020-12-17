# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchServicePresenter do
  let(:user) { create(:user) }
  let(:search_service) { SearchService.new(user, search: search, scope: scope) }
  let(:presenter) { described_class.new(search_service, current_user: user) }

  describe '#show_results_status?' do
    using RSpec::Parameterized::TableSyntax

    let(:search) { '' }
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
end
