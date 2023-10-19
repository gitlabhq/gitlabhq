# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::ReferenceParser::MergeRequestParser, feature_category: :code_review_workflow do
  include ReferenceParserHelpers

  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public, group: group) }
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  subject(:parser) { described_class.new(Banzai::RenderContext.new(merge_request.target_project, user)) }

  let(:link) { empty_html_link }

  describe '#nodes_visible_to_user' do
    context 'when the link has a data-issue attribute' do
      before do
        project.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
        link['data-project'] = merge_request.project_id.to_s
        link['data-merge-request'] = merge_request.id.to_s
      end

      it_behaves_like "referenced feature visibility", "merge_requests"
    end
  end

  describe '#referenced_by' do
    describe 'when the link has a data-merge-request attribute' do
      context 'using an existing merge request ID' do
        it 'returns an Array of merge requests' do
          link['data-project'] = merge_request.project_id.to_s
          link['data-merge-request'] = merge_request.id.to_s

          expect(subject.referenced_by([link])).to eq([merge_request])
        end
      end

      context 'using a non-existing merge request ID' do
        it 'returns an empty Array' do
          link['data-project'] = merge_request.project_id.to_s
          link['data-merge-request'] = ''

          expect(subject.referenced_by([link])).to eq([])
        end
      end
    end
  end

  context 'when checking multiple merge requests on another project' do
    let(:other_project) { create(:project, :public) }
    let(:other_merge_request) { create(:merge_request, source_project: other_project) }

    let!(:control_links) do
      [merge_request_link(other_merge_request)]
    end

    let!(:actual_links) do
      control_links + [merge_request_link(create(:merge_request, :conflict, source_project: other_project))]
    end

    def merge_request_link(merge_request)
      Nokogiri::HTML.fragment(%(<a data-project="#{merge_request.project_id}" data-merge-request="#{merge_request.id}"></a>)).children[0]
    end

    before do
      project.add_developer(user)
    end

    it_behaves_like 'no N+1 queries'
  end

  describe '#can_read_reference?' do
    subject { parser.can_read_reference?(user, merge_request) }

    it { is_expected.to be_truthy }

    context 'when merge request belongs to the private project' do
      let(:project) { create(:project, :private) }

      it 'prevents user from reading merge request references' do
        is_expected.to be_falsey
      end

      context 'when user has access to the project' do
        before do
          project.add_developer(user)
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'with memoization' do
      context 'when project is the same' do
        it 'calls #can? only once' do
          expect(parser).to receive(:can?).once

          2.times { parser.can_read_reference?(user, merge_request) }
        end
      end

      context 'when merge requests belong to different projects' do
        it 'calls #can? for each project' do
          expect(parser).to receive(:can?).twice

          another_merge_request = create(:merge_request)

          2.times do
            parser.can_read_reference?(user, merge_request)
            parser.can_read_reference?(user, another_merge_request)
          end
        end
      end
    end
  end
end
