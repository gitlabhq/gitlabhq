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

  describe '#to_html' do
    let(:html) { Nokogiri::HTML.parse(badge.to_html) }
    let(:a_href) { html.at('a') }

    it 'points to link' do
      expect(a_href[:href]).to eq badge.link_url
    end

    it 'contains clickable image' do
      expect(a_href.children.first.name).to eq 'img'
    end
  end

  describe '#to_markdown' do
    subject { badge.to_markdown }

    it { is_expected.to include badge.image_url }
    it { is_expected.to include badge.link_url }
  end

  describe '#image_url' do
    subject { badge.image_url }
    it { is_expected.to include "badges/#{branch}/build.svg" }
  end

  describe '#link_url' do
    subject { badge.link_url }
    it { is_expected.to include "commits/#{branch}" }
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
