# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::ReferenceParser::WorkItemParser, feature_category: :markdown do
  include ReferenceParserHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be_with_reload(:project) { create(:project, :public, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:work_item) { create(:work_item, project: project) }
  let_it_be(:link) { empty_html_link }

  subject { described_class.new(Banzai::RenderContext.new(project, user)) }

  describe '#records_for_nodes' do
    it 'returns a Hash containing the work items for a list of nodes' do
      link['data-work-item'] = work_item.id.to_s
      nodes = [link]

      expect(subject.records_for_nodes(nodes)).to eq({ link => work_item })
    end
  end

  context 'when checking multiple work items on another project' do
    let_it_be(:other_project) { create(:project, :public) }
    let_it_be(:other_work_item) { create(:work_item, project: other_project) }
    let_it_be(:control_links) do
      [work_item_link(other_work_item)]
    end

    let_it_be(:actual_links) do
      control_links + [work_item_link(create(:work_item, project: other_project))]
    end

    def work_item_link(work_item)
      Nokogiri::HTML.fragment(%(<a data-work-item="#{work_item.id}"></a>)).children[0]
    end

    before do
      project.add_developer(user)
    end

    it_behaves_like 'no N+1 queries'
  end
end
