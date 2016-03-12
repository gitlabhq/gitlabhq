require 'spec_helper'

describe Gitlab::ProjectSearchResults, lib: true do
  let(:project) { create(:project) }
  let(:query) { 'hello world' }

  describe 'initialize with empty ref' do
    let(:results) { Gitlab::ProjectSearchResults.new(project, query, '') }

    it { expect(results.project).to eq(project) }
    it { expect(results.repository_ref).to be_nil }
    it { expect(results.query).to eq('hello world') }
  end

  describe 'initialize with ref' do
    let(:ref) { 'refs/heads/test' }
    let(:results) { Gitlab::ProjectSearchResults.new(project, query, ref) }

    it { expect(results.project).to eq(project) }
    it { expect(results.repository_ref).to eq(ref) }
    it { expect(results.query).to eq('hello world') }
  end
end
