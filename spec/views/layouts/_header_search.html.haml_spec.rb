# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/_header_search' do
  let(:project) { nil }
  let(:group) { nil }
  let(:scope) { nil }
  let(:ref) { nil }
  let(:code_search) { false }
  let(:for_snippets) { false }

  let(:header_search_context) do
    {
      project: project,
      group: group,
      scope: scope,
      ref: ref,
      code_search: code_search,
      for_snippets: for_snippets
    }
  end

  before do
    allow(view).to receive(:header_search_context).and_return(header_search_context)
  end

  shared_examples 'hidden fields are properly set' do
    context 'when search_context has a scope value' do
      let(:scope) { 'issues' }

      it 'sets scope input to issues' do
        render

        expect(rendered).to have_css("input[name='scope'][value='#{scope}']", count: 1, visible: false)
      end
    end

    context 'when search_context has a code_search value' do
      let(:code_search) { true }

      it 'sets search_code input to true' do
        render

        expect(rendered).to have_css("input[name='search_code'][value='#{code_search}']", count: 1, visible: false)
      end
    end

    context 'when search_context has a ref value' do
      let(:ref) { 'test-branch' }

      it 'sets repository_ref input to test-branch' do
        render

        expect(rendered).to have_css("input[name='repository_ref'][value='#{ref}']", count: 1, visible: false)
      end
    end

    context 'when search_context has a for_snippets value' do
      let(:for_snippets) { true }

      it 'sets for_snippets input to true' do
        render

        expect(rendered).to have_css("input[name='snippets'][value='#{for_snippets}']", count: 1, visible: false)
      end
    end

    context 'nav_source' do
      it 'always set to navbar' do
        render

        expect(rendered).to have_css("input[name='nav_source'][value='navbar']", count: 1, visible: false)
      end
    end

    context 'submit button' do
      it 'always renders for specs' do
        render

        expect(rendered).to have_css('noscript button', text: 'Search')
      end
    end
  end

  context 'when doing a project level search' do
    let(:project) do
      { id: 123, name: 'foo' }
    end

    it 'sets project_id field' do
      render

      expect(rendered).to have_css("input[name='project_id'][value='#{project[:id]}']", count: 1, visible: false)
    end

    it_behaves_like 'hidden fields are properly set'
  end

  context 'when doing a group level search' do
    let(:group) do
      { id: 123, name: 'bar' }
    end

    it 'sets group_id field' do
      render

      expect(rendered).to have_css("input[name='group_id'][value='#{group[:id]}']", count: 1, visible: false)
    end

    it_behaves_like 'hidden fields are properly set'
  end
end
