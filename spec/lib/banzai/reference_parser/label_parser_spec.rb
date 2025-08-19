# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::ReferenceParser::LabelParser, feature_category: :markdown do
  include ReferenceParserHelpers

  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }
  let(:label) { create(:label, project: project) }
  let(:link) { empty_html_link }

  subject { described_class.new(Banzai::RenderContext.new(project, user)) }

  describe '#nodes_visible_to_user' do
    context 'when the link has a data-issue attribute' do
      before do
        link['data-label'] = label.id.to_s
      end

      it_behaves_like "referenced feature visibility", "issues", "merge_requests"
    end
  end

  describe '#referenced_by' do
    describe 'when the link has a data-label attribute' do
      context 'using an existing label ID' do
        it 'returns an Array of labels' do
          link['data-label'] = label.id.to_s

          expect(subject.referenced_by([link])).to eq([label])
        end
      end

      context 'using a non-existing label ID' do
        it 'returns an empty Array' do
          link['data-label'] = ''

          expect(subject.referenced_by([link])).to eq([])
        end
      end
    end
  end
end
