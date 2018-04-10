require 'spec_helper'

describe Banzai::ReferenceParser::MergeRequestParser do
  include ReferenceParserHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  subject { described_class.new(project, user) }
  let(:link) { empty_html_link }

  describe '#nodes_visible_to_user' do
    context 'when the link has a data-issue attribute' do
      before do
        project.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
        link['data-merge-request'] = merge_request.id.to_s
      end

      it_behaves_like "referenced feature visibility", "merge_requests"
    end
  end

  describe '#referenced_by' do
    describe 'when the link has a data-merge-request attribute' do
      context 'using an existing merge request ID' do
        it 'returns an Array of merge requests' do
          link['data-merge-request'] = merge_request.id.to_s

          expect(subject.referenced_by([link])).to eq([merge_request])
        end
      end

      context 'using a non-existing merge request ID' do
        it 'returns an empty Array' do
          link['data-merge-request'] = ''

          expect(subject.referenced_by([link])).to eq([])
        end
      end
    end
  end

  context 'when checking multiple merge requests on another project' do
    let(:other_project) { create(:project, :public) }
    let(:other_merge_request) { create(:merge_request, source_project: other_project) }

    let(:control_links) do
      [merge_request_link(other_merge_request)]
    end

    let(:actual_links) do
      control_links + [merge_request_link(create(:merge_request, :conflict, source_project: other_project))]
    end

    def merge_request_link(merge_request)
      Nokogiri::HTML.fragment(%Q{<a data-merge-request="#{merge_request.id}"></a>}).children[0]
    end

    before do
      project.add_developer(user)
    end

    it_behaves_like 'no N+1 queries'
  end
end
