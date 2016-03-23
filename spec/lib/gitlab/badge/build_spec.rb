require 'spec_helper'

describe Gitlab::Badge::Build do
  let(:project) { create(:project) }
  let(:sha) { project.commit.sha }
  let(:ci_commit) { create(:ci_commit, project: project, sha: sha) }
  let(:badge) { described_class.new(project, 'master') }

  let!(:build) { create(:ci_build, commit: ci_commit) }

  describe '#type' do
    subject { badge.type }
    it { is_expected.to eq 'image/svg+xml' }
  end

  context 'build success' do
    before { build.success! }

    describe '#to_s' do
      subject { badge.to_s }
      it { is_expected.to eq 'build-success' }
    end

    describe '#data' do
      let(:data) { badge.data }
      let(:xml) { Nokogiri::XML.parse(data) }

      it 'contains infromation about success' do
        expect(xml.at(%Q{text:contains("success")})).to be_truthy
      end
    end
  end
end
