# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/merge_requests/_mr_box.html.haml', feature_category: :code_review_workflow do
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- the title is rendered through Banzai, which
  # needs persisted records to resolve and autolink references
  let_it_be(:project) { create(:project) }

  before do
    assign(:project, project)
    assign(:merge_request, merge_request)

    allow(view).to receive_messages(fluid_layout: false, merge_request_header: '')
  end

  context 'when the title contains inline code' do
    let_it_be(:merge_request) do
      create(:merge_request, source_project: project, target_project: project, title: 'Fix `foo` bar')
    end

    it 'renders the inline code as code markup' do
      render

      expect(rendered).to have_selector('a.merge-request-sticky-title code', text: 'foo')
    end
  end

  context 'when the title contains a reference that autolinks' do
    let_it_be(:merge_request) do
      create(:merge_request, source_project: project, target_project: project).tap do |mr|
        mr.update!(title: "Fix #{mr.to_reference}")
      end
    end

    it 'strips the nested link to avoid nested anchors' do
      render

      sticky_title = Nokogiri::HTML.fragment(rendered).at_css('a.merge-request-sticky-title')
      expect(sticky_title).to be_present
      expect(sticky_title.css('a')).to be_empty
    end
  end
  # rubocop:enable RSpec/FactoryBot/AvoidCreate
end
