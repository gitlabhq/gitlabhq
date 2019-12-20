# frozen_string_literal: true

require 'spec_helper'

describe Banzai::ReferenceParser::MentionedGroupParser do
  include ReferenceParserHelpers

  let(:group) { create(:group, :private) }
  let(:user) { create(:user) }
  let(:new_user) { create(:user) }
  let(:project) { create(:project, group: group, creator: user) }
  let(:link) { empty_html_link }

  subject { described_class.new(Banzai::RenderContext.new(project, new_user)) }

  describe '#gather_references' do
    context 'when the link has a data-group attribute' do
      context 'using an existing group ID where user does not have access' do
        it 'returns empty array' do
          link['data-group'] = project.group.id.to_s

          expect(subject.gather_references([link])).to eq([])
        end
      end

      context 'using an existing group ID' do
        before do
          link['data-group'] = project.group.id.to_s
          group.add_developer(new_user)
        end

        it 'returns groups' do
          expect(subject.gather_references([link])).to eq([group])
        end
      end

      context 'using a non-existing group ID' do
        it 'returns an empty Array' do
          link['data-group'] = 'test-non-existing'

          expect(subject.gather_references([link])).to eq([])
        end
      end
    end
  end
end
