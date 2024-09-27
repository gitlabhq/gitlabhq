# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::ReferenceParser::MentionedUserParser, feature_category: :markdown do
  include ReferenceParserHelpers

  let(:group) { create(:group, :private) }
  let(:user) { create(:user) }
  let(:new_user) { create(:user) }
  let(:project) { create(:project, group: group, creator: user) }
  let(:link) { empty_html_link }

  subject { described_class.new(Banzai::RenderContext.new(project, new_user)) }

  describe '#gather_references' do
    context 'when the link has a data-group attribute' do
      context 'using an existing group ID' do
        before do
          link['data-group'] = project.group.id.to_s
          group.add_developer(new_user)
        end

        it 'returns empty list of users' do
          expect_gathered_references(subject.gather_references([link]), [], [link], [link])
        end
      end
    end

    context 'when the link has a data-project attribute' do
      context 'using an existing project ID' do
        before do
          link['data-project'] = project.id.to_s
          project.add_developer(new_user)
        end

        it 'returns empty list of users' do
          expect_gathered_references(subject.gather_references([link]), [], [link], [link])
        end
      end
    end

    context 'when the link has a data-user attribute' do
      it 'returns an Array of users' do
        link['data-user'] = user.id.to_s

        expect_gathered_references(subject.gather_references([link]), [user], [link], [link])
      end
    end
  end
end
