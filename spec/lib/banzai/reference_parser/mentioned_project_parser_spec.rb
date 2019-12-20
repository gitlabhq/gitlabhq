# frozen_string_literal: true

require 'spec_helper'

describe Banzai::ReferenceParser::MentionedProjectParser do
  include ReferenceParserHelpers

  let(:group) { create(:group, :private) }
  let(:user) { create(:user) }
  let(:new_user) { create(:user) }
  let(:project) { create(:project, group: group, creator: user) }
  let(:link) { empty_html_link }

  subject { described_class.new(Banzai::RenderContext.new(project, new_user)) }

  describe '#gather_references' do
    context 'when the link has a data-project attribute' do
      context 'using an existing project ID where user does not have access' do
        it 'returns empty Array' do
          link['data-project'] = project.id.to_s

          expect(subject.gather_references([link])).to eq([])
        end
      end

      context 'using an existing project ID' do
        before do
          link['data-project'] = project.id.to_s
          project.add_developer(new_user)
        end

        it 'returns an Array of referenced projects' do
          expect(subject.gather_references([link])).to eq([project])
        end
      end

      context 'using a non-existing project ID' do
        it 'returns an empty Array' do
          link['data-project'] = 'inexisting-project-id'

          expect(subject.gather_references([link])).to eq([])
        end
      end
    end
  end
end
