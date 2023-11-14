# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/commit/branches.html.haml' do
  let(:project) { create(:project, :repository) }

  before do
    assign(:project, project)
  end

  context 'when branches and tags are available' do
    before do
      assign(:branches, %w[master test-branch])
      assign(:branches_limit_exceeded, false)
      assign(:tags, ['tag1'])
      assign(:tags_limit_exceeded, false)

      render
    end

    it 'shows default branch' do
      expect(rendered).to have_link('master')
    end

    it 'shows js expand link' do
      expect(rendered).to have_selector('.js-details-expand')
    end

    it 'shows branch and tag links' do
      expect(rendered).to have_link('test-branch')
      expect(rendered).to have_link('tag1')
    end
  end

  context 'when branches are available but no tags' do
    before do
      assign(:branches, %w[master test-branch])
      assign(:branches_limit_exceeded, false)
      assign(:tags, [])
      assign(:tags_limit_exceeded, true)

      render
    end

    it 'shows branches' do
      expect(rendered).to have_link('master')
      expect(rendered).to have_link('test-branch')
    end

    it 'shows js expand link' do
      expect(rendered).to have_selector('.js-details-expand')
    end

    it 'shows limit exceeded message for tags' do
      expect(rendered).to have_text('Tags unavailable')
    end
  end

  context 'when tags are available but no branches (just default)' do
    before do
      assign(:branches, ['master'])
      assign(:branches_limit_exceeded, true)
      assign(:tags, %w[tag1 tag2])
      assign(:tags_limit_exceeded, false)

      render
    end

    it 'shows default branch' do
      expect(rendered).to have_text('master')
    end

    it 'shows js expand link' do
      expect(rendered).to have_selector('.js-details-expand')
    end

    it 'shows tags' do
      expect(rendered).to have_link('tag1')
      expect(rendered).to have_link('tag2')
    end

    it 'shows limit exceeded for branches' do
      expect(rendered).to have_text('Branches unavailable')
    end
  end

  context 'when branches and tags are not available' do
    before do
      assign(:branches, ['master'])
      assign(:branches_limit_exceeded, true)
      assign(:tags, [])
      assign(:tags_limit_exceeded, true)

      render
    end

    it 'shows default branch' do
      expect(rendered).to have_text('master')
    end

    it 'shows js expand link' do
      expect(rendered).to have_selector('.js-details-expand')
    end

    it 'shows too many to search' do
      expect(rendered).to have_text('Branches unavailable')
      expect(rendered).to have_text('Tags unavailable')
    end
  end
end
