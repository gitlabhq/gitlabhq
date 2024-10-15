# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::ReferenceParser::WikiPageParser, feature_category: :markdown do
  include ReferenceParserHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:link) { empty_html_link }

  describe '#nodes_visible_to_user' do
    before do
      link['data-reference-type'] = 'wiki_page'
    end

    context 'when the link has a data-project attribute' do
      before do
        link['data-project'] = project.id
      end

      it 'redacts the link if the user cannot read the project' do
        nodes = described_class
          .new(Banzai::RenderContext.new(project, user))
          .nodes_visible_to_user(user, [link])

        expect(nodes).to be_empty
      end
    end

    context 'when the link has a data-group attribute' do
      before do
        link['data-group'] = group.id
      end

      it 'redacts the link if the user cannot read the group' do
        nodes = described_class
          .new(Banzai::RenderContext.new(group, user))
          .nodes_visible_to_user(user, [link])

        expect(nodes).to be_empty
      end
    end

    context 'if no data-project or data-group attribute is present' do
      it 'returns the link' do
        nodes = described_class
          .new(Banzai::RenderContext.new(project, user))
          .nodes_visible_to_user(user, [link])

        expect(nodes).to eq([link])
      end
    end
  end
end
