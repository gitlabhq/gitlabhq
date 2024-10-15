# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::ReferenceParser::AlertParser, feature_category: :markdown do
  include ReferenceParserHelpers

  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }
  let(:alert) { create(:alert_management_alert, project: project) }

  subject { described_class.new(Banzai::RenderContext.new(project, user)) }

  let(:link) { empty_html_link }

  describe '#nodes_visible_to_user' do
    context 'when the link has a data-issue attribute' do
      before do
        link['data-alert'] = alert.id.to_s
      end

      it_behaves_like "referenced feature visibility", "issues", "merge_requests" do
        before do
          project.add_developer(user) if enable_user?
        end
      end
    end
  end

  describe '#referenced_by' do
    describe 'when the link has a data-alert attribute' do
      context 'using an existing alert ID' do
        it 'returns an Array of alerts' do
          link['data-alert'] = alert.id.to_s

          expect(subject.referenced_by([link])).to eq([alert])
        end
      end

      context 'using a non-existing alert ID' do
        it 'returns an empty Array' do
          link['data-alert'] = ''

          expect(subject.referenced_by([link])).to eq([])
        end
      end
    end
  end
end
