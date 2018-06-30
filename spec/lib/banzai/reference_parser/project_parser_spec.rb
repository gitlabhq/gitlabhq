require 'spec_helper'

describe Banzai::ReferenceParser::ProjectParser do
  include ReferenceParserHelpers

  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }
  subject { described_class.new(Banzai::RenderContext.new(project, user)) }
  let(:link) { empty_html_link }

  describe '#referenced_by' do
    describe 'when the link has a data-project attribute' do
      context 'using an existing project ID' do
        it 'returns an Array of projects' do
          link['data-project'] = project.id.to_s

          expect(subject.referenced_by([link])).to eq([project])
        end
      end

      context 'using a non-existing project ID' do
        it 'returns an empty Array' do
          link['data-project'] = ''

          expect(subject.referenced_by([link])).to eq([])
        end
      end
    end
  end
end
