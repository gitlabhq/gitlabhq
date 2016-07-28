require 'spec_helper'

describe Gitlab::Badge::Build do
  let(:project) { create(:project) }
  let(:sha) { project.commit.sha }
  let(:branch) { 'master' }
  let(:badge) { described_class.new(project, branch) }

  describe '#type' do
    subject { badge.type }
    it { is_expected.to eq 'image/svg+xml' }
  end

  describe '#metadata' do
    it 'returns badge metadata' do
      expect(badge.metadata.image_url)
        .to include 'badges/master/build.svg'
    end
  end

  context 'build exists' do
    let!(:build) { create_build(project, sha, branch) }

    context 'build success' do
      before { build.success! }

      describe '#to_s' do
        subject { badge.to_s }
        it { is_expected.to eq 'build-success' }
      end

      describe '#data' do
        let(:data) { badge.data }

        it 'contains information about success' do
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

        it 'contains information about failure' do
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

  context 'when outdated pipeline for given ref exists' do
    before do
      build = create_build(project, sha, branch)
      build.success!

      old_build = create_build(project, '11eeffdd', branch)
      old_build.drop!
    end

    it 'does not take outdated pipeline into account' do
      expect(badge.to_s).to eq 'build-success'
    end
  end

  def create_build(project, sha, branch)
    pipeline = create(:ci_pipeline, project: project,
                                    sha: sha,
                                    ref: branch)

    create(:ci_build, pipeline: pipeline, stage: 'notify')
  end

  def status_node(data, status)
    xml = Nokogiri::XML.parse(data)
    xml.at(%Q{text:contains("#{status}")})
  end
end
