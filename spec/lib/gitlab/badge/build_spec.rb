require 'spec_helper'

describe Gitlab::Badge::Build do
  let(:project) { create(:project) }
  let(:sha) { project.commit.sha }
  let(:badge) { described_class.new(project, 'master') }

  describe '#type' do
    subject { badge.type }
    it { is_expected.to eq 'image/svg+xml' }
  end

  context 'build exists' do
    let(:ci_commit) { create(:ci_commit, project: project, sha: sha) }
    let!(:build) { create(:ci_build, commit: ci_commit) }


    context 'build success' do
      before { build.success! }

      describe '#to_s' do
        subject { badge.to_s }
        it { is_expected.to eq 'build-success' }
      end

      describe '#data' do
        let(:data) { badge.data }

        it 'contains infromation about success' do
          expect(status_node(data, 'success')).to be_truthy
        end
      end
    end

    context 'build failed' do
      before { build.drop! }

      describe '#to_s' do
        subject { badge.to_s }
        it { is_expected.to eq 'build-failed' }
      end

      describe '#data' do
        let(:data) { badge.data }

        it 'contains infromation about failure' do
          expect(status_node(data, 'failed')).to be_truthy
        end
      end
    end
  end

  context 'build does not exist' do
    describe '#to_s' do
      subject { badge.to_s }
      it { is_expected.to eq 'build-unknown' }
    end

    describe '#data' do
      let(:data) { badge.data }

      it 'contains infromation about unknown build' do
        expect(status_node(data, 'unknown')).to be_truthy
      end
    end
  end

  def status_node(data, status)
    xml = Nokogiri::XML.parse(data)
    xml.at(%Q{text:contains("#{status}")})
  end
end
