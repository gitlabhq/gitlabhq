# frozen_string_literal: true

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

          expect(subject.gather_references([link])).to eq([project])
        end
      end

      context 'using a non-existing project ID' do
        it 'returns an empty Array' do
          link['data-project'] = ''

          expect(subject.gather_references([link])).to eq([])
        end
      end

      context 'using a private project ID' do
        it 'returns an empty Array when unauthorized' do
          private_project = create(:project, :private)

          link['data-project'] = private_project.id.to_s

          expect(subject.gather_references([link])).to eq([])
        end

        it 'returns an Array when authorized' do
          private_project = create(:project, :private, namespace: user.namespace)

          link['data-project'] = private_project.id.to_s

          expect(subject.gather_references([link])).to eq([private_project])
        end
      end
    end
  end
end
