require 'spec_helper'

describe Banzai::ReferenceParser::MergeRequestParser, lib: true do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:parser) { described_class.new(merge_request.target_project, user, user) }
  let(:link) { Nokogiri::HTML.fragment('<a></a>').children[0] }

  describe '#referenced_by' do
    it 'returns an Array of Banzai::LazyReference instances' do
      link['data-merge-request'] = merge_request.id.to_s

      refs = parser.referenced_by(link)

      expect(refs).to be_an_instance_of(Array)

      expect(refs[0]).to be_an_instance_of(Banzai::LazyReference)
      expect(refs[0].klass).to eq(MergeRequest)
      expect(refs[0].ids).to eq([merge_request.id])
    end
  end
end
