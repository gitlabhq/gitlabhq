require 'spec_helper'

describe EnvironmentStatus do
  let(:deployment)    { create(:deployment, :succeed, :review_app) }
  let(:environment)   { deployment.environment}
  let(:project)       { deployment.project }
  let(:merge_request) { create(:merge_request, :deployed_review_app, deployment: deployment) }
  let(:sha)           { deployment.sha }

  subject(:environment_status) { described_class.new(environment, merge_request, sha) }

  it { is_expected.to delegate_method(:id).to(:environment) }
  it { is_expected.to delegate_method(:name).to(:environment) }
  it { is_expected.to delegate_method(:project).to(:environment) }
  it { is_expected.to delegate_method(:deployed_at).to(:deployment) }
  it { is_expected.to delegate_method(:status).to(:deployment) }

  describe '#project' do
    subject { environment_status.project }

    it { is_expected.to eq(project) }
  end

  describe '#merge_request' do
    subject { environment_status.merge_request }

    it { is_expected.to eq(merge_request) }
  end

  describe '#deployment' do
    subject { environment_status.deployment }

    it { is_expected.to eq(deployment) }
  end

  # $ git diff --stat pages-deploy-target...pages-deploy
  # .gitlab/route-map.yml              |  5 +++++
  # files/html/500.html                | 13 -------------
  # files/html/page.html               |  3 +++
  # files/js/application.js            |  3 +++
  # files/markdown/ruby-style-guide.md |  4 ++++
  # pages-deploy.txt                   |  1 +
  #
  # $ cat .gitlab/route-map.yml
  # - source: /files\/markdown\/(.+)\.md$/
  #   public: '\1.html'
  #
  # - source: /files\/(.+)/
  #   public: '\1'
  describe '#changes' do
    it 'contains only added and modified public pages' do
      expect(environment_status.changes).to contain_exactly(
        {
          path: 'ruby-style-guide.html',
          external_url: "#{environment.external_url}/ruby-style-guide.html"
        }, {
          path: 'html/page.html',
          external_url: "#{environment.external_url}/html/page.html"
        }
      )
    end
  end

  describe '.for_merge_request' do
    let(:admin)    { create(:admin) }
    let(:pipeline) { create(:ci_pipeline, sha: sha) }

    it 'is based on merge_request.head_pipeline' do
      expect(merge_request).to receive(:head_pipeline).and_return(pipeline)
      expect(merge_request).not_to receive(:merge_pipeline)

      described_class.for_merge_request(merge_request, admin)
    end
  end

  describe '.after_merge_request' do
    let(:admin)    { create(:admin) }
    let(:pipeline) { create(:ci_pipeline, sha: sha) }

    before do
      merge_request.mark_as_merged!
    end

    it 'is based on merge_request.merge_pipeline' do
      expect(merge_request).to receive(:merge_pipeline).and_return(pipeline)
      expect(merge_request).not_to receive(:head_pipeline)

      described_class.after_merge_request(merge_request, admin)
    end
  end
end
