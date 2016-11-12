require 'spec_helper'

describe CommitEntity do
  let(:entity) do
    described_class.new(commit, request: request)
  end

  let(:request) { double('request') }
  let(:project) { create(:project) }
  let(:commit) { project.commit }

  subject { entity.as_json }

  before do
    allow(request).to receive(:project).and_return(project)
  end

  context 'when commit author is a user' do
    before do
      create(:user, email: commit.author_email)
    end

    it 'contains information about user' do
      expect(subject.fetch(:author)).not_to be_nil
    end
  end

  context 'when commit author is not a user' do
    it 'does not contain author details' do
      expect(subject.fetch(:author)).to be_nil
    end
  end

  it 'contains commit URL' do
    expect(subject).to include(:commit_url)
  end

  it 'needs to receive project in the request' do
    expect(request).to receive(:project)
      .and_return(project)

    subject
  end

  it 'exposes gravatar url that belongs to author' do
    expect(subject.fetch(:author_gravatar_url)).to match /gravatar/
  end
end
