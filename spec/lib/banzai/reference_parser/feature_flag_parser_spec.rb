# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::ReferenceParser::FeatureFlagParser, feature_category: :feature_flags do
  include ReferenceParserHelpers

  subject { described_class.new(Banzai::RenderContext.new(project, user)) }

  let(:link) { empty_html_link }

  describe '#nodes_visible_to_user' do
    let(:project) { create(:project, :public) }
    let(:user) { create(:user) }
    let(:feature_flag) { create(:operations_feature_flag, project: project) }

    context 'when the link has a data-issue attribute' do
      before do
        link['data-feature-flag'] = feature_flag.id.to_s
      end

      it_behaves_like "referenced feature visibility", "issues", "merge_requests" do
        before do
          project.add_developer(user) if enable_user?
        end
      end
    end
  end

  describe '#referenced_by' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:user) { create(:user) }
    let_it_be(:feature_flag) { create(:operations_feature_flag, project: project) }

    describe 'when the link has a data-feature-flag attribute' do
      context 'using an existing feature flag ID' do
        it 'returns an Array of feature flags' do
          link['data-feature-flag'] = feature_flag.id.to_s

          expect(subject.referenced_by([link])).to eq([feature_flag])
        end
      end

      context 'using a non-existing feature flag ID' do
        it 'returns an empty Array' do
          link['data-feature-flag'] = ''

          expect(subject.referenced_by([link])).to eq([])
        end
      end
    end
  end
end
