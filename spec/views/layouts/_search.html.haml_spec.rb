# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/_search' do
  let(:group) { nil }
  let(:project) { nil }
  let(:scope) { 'issues' }
  let(:search_context) do
    instance_double(Gitlab::SearchContext,
      project: project,
      group: group,
      scope: scope,
      ref: nil,
      snippets: [],
      search_url: '/search',
      project_metadata: {},
      group_metadata: {})
  end

  before do
    allow(view).to receive(:search_context).and_return(search_context)
    allow(search_context).to receive(:code_search?).and_return(false)
    allow(search_context).to receive(:for_snippets?).and_return(false)
  end

  shared_examples 'search context scope is set' do
    context 'when rendering' do
      it 'sets the placeholder' do
        render

        expect(rendered).to include('placeholder="Search GitLab"')
        expect(rendered).to include('aria-label="Search GitLab"')
      end
    end

    context 'when on issues' do
      it 'sets scope to issues' do
        render

        expect(rendered).to have_css("input[name='scope'][value='issues']", count: 1, visible: false)
      end
    end

    context 'when on merge requests' do
      let(:scope) { 'merge_requests' }

      it 'sets scope to merge_requests' do
        render

        expect(rendered).to have_css("input[name='scope'][value='merge_requests']", count: 1, visible: false)
      end
    end
  end

  context 'when doing project level search' do
    let(:project) { create(:project) }

    before do
      allow(search_context).to receive(:for_project?).and_return(true)
      allow(search_context).to receive(:for_group?).and_return(false)
    end

    it_behaves_like 'search context scope is set'
  end

  context 'when doing group level search' do
    let(:group) { create(:group) }

    before do
      allow(search_context).to receive(:for_project?).and_return(false)
      allow(search_context).to receive(:for_group?).and_return(true)
    end

    it_behaves_like 'search context scope is set'
  end
end
