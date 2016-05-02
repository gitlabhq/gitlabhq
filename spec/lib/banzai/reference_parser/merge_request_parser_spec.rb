require 'spec_helper'

describe Banzai::ReferenceParser::MergeRequestParser, lib: true do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:parser) { described_class.new(merge_request.target_project, user, user) }
  let(:link) { Nokogiri::HTML.fragment('<a></a>').children[0] }

  describe '#referenced_by' do
    describe 'when the link has a data-merge-request attribute' do
      context 'using an existing merge request ID' do
        it 'returns an Array of merge requests' do
          link['data-merge-request'] = merge_request.id.to_s

          expect(parser.referenced_by([link])).to eq([merge_request])
        end
      end

      context 'using a non-existing merge request ID' do
        it 'returns an empty Array' do
          link['data-merge-request'] = ''

          expect(parser.referenced_by([link])).to eq([])
        end
      end
    end
  end
end
