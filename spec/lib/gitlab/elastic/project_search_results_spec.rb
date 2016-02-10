require 'spec_helper'

describe Gitlab::Elastic::ProjectSearchResults, lib: true do
  before do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(true)
    Project.__elasticsearch__.create_index!

    @project = create(:project)
  end

  after do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(false)
    Project.__elasticsearch__.delete_index!
  end

  let(:query) { 'hello world' }

  describe 'initialize with empty ref' do
    let(:results) { Gitlab::Elastic::ProjectSearchResults.new(@project.id, query, '') }

    it { expect(results.project).to eq(@project) }
    it { expect(results.repository_ref).to be_nil }
    it { expect(results.query).to eq('hello world') }
  end

  describe 'initialize with ref' do
    let(:ref) { 'refs/heads/test' }
    let(:results) { Gitlab::Elastic::ProjectSearchResults.new(@project.id, query, ref) }

    it { expect(results.project).to eq(@project) }
    it { expect(results.repository_ref).to eq(ref) }
    it { expect(results.query).to eq('hello world') }
  end
end
