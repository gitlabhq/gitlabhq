# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::ReferenceParser::DesignParser, feature_category: :design_management do
  include ReferenceParserHelpers
  include DesignManagementTestHelpers

  let_it_be(:issue) { create(:issue) }
  let_it_be(:design) { create(:design, :with_versions, issue: issue) }
  let_it_be(:user) { create(:user, developer_of: issue.project) }

  subject(:instance) { described_class.new(Banzai::RenderContext.new(issue.project, user)) }

  let(:link) { design_link(design) }

  before do
    enable_design_management
  end

  describe '#nodes_visible_to_user' do
    it_behaves_like 'referenced feature visibility', 'issues' do
      let(:project) { issue.project }
    end

    describe 'specific states' do
      let_it_be(:public_project) { create(:project, :public) }

      let_it_be(:other_project_link) do
        design_link(create(:design, :with_versions))
      end

      let_it_be(:public_link) do
        design_link(create(:design, :with_versions, issue: create(:issue, project: public_project)))
      end

      let_it_be(:public_but_confidential_link) do
        design_link(create(:design, :with_versions, issue: create(:issue, :confidential, project: public_project)))
      end

      subject(:visible_nodes) do
        nodes = [link,
                 other_project_link,
                 public_link,
                 public_but_confidential_link]

        instance.nodes_visible_to_user(user, nodes)
      end

      it 'redacts links we should not have access to' do
        expect(visible_nodes).to contain_exactly(link, public_link)
      end

      context 'design management is not available' do
        before do
          enable_design_management(false)
        end

        it 'redacts all nodes' do
          expect(visible_nodes).to be_empty
        end
      end
    end
  end

  describe '#process' do
    it 'returns the correct designs' do
      frag = document([design, create(:design, :with_versions)])

      expect(subject.process([frag])[:visible]).to contain_exactly(design)
    end
  end

  def design_link(design)
    node = empty_html_link
    node['class'] = 'gfm'
    node['data-reference-type'] = 'design'
    node['data-project'] = design.project.id.to_s
    node['data-issue'] = design.issue.id.to_s
    node['data-design'] = design.id.to_s

    node
  end

  def document(designs)
    frag = Nokogiri::HTML.fragment('')
    designs.each do |design|
      frag.add_child(design_link(design))
    end

    frag
  end
end
