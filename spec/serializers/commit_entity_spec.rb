# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitEntity do
  let(:entity) do
    described_class.new(commit, request: request)
  end

  let(:request) { double('request') }
  let(:project) { create(:project, :repository) }
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

  it 'contains path to commit' do
    expect(subject).to include(:commit_path)
    expect(subject[:commit_path]).to include "commit/#{commit.id}"
  end

  it 'contains URL to commit' do
    expect(subject).to include(:commit_url)
    expect(subject[:commit_path]).to include "commit/#{commit.id}"
  end

  it 'needs to receive project in the request' do
    expect(request).to receive(:project)
      .and_return(project)

    subject
  end

  it 'exposes gravatar url that belongs to author' do
    expect(subject.fetch(:author_gravatar_url)).to match(/gravatar/)
  end

  context 'when type is not set' do
    it 'does not expose extra properties' do
      expect(subject).not_to include(:description_html)
      expect(subject).not_to include(:title_html)
    end
  end

  context 'when type is "full"' do
    let(:entity) do
      described_class.new(commit, request: request, type: :full, pipeline_ref: project.default_branch, pipeline_project: project)
    end

    it 'exposes extra properties' do
      expect(subject).to include(:description_html)
      expect(subject).to include(:title_html)
      expect(subject.fetch(:description_html)).not_to be_nil
      expect(subject.fetch(:title_html)).not_to be_nil
    end

    context 'when commit has signature' do
      let(:commit) { project.commit(TestEnv::BRANCH_SHA['signed-commits']) }

      it 'exposes "signature_html"' do
        expect(subject.fetch(:signature_html)).not_to be_nil
      end
    end

    context 'when commit has pipeline' do
      before do
        create(:ci_pipeline, project: project, sha: commit.id)
      end

      it 'exposes "pipeline_status_path"' do
        expect(subject.fetch(:pipeline_status_path)).not_to be_nil
      end
    end
  end

  context 'when commit_url_params is set' do
    let(:entity) do
      params = { merge_request_iid: 3 }

      described_class.new(commit, request: request, commit_url_params: params)
    end

    it 'adds commit_url_params to url and path' do
      expect(subject[:commit_path]).to include "?merge_request_iid=3"
      expect(subject[:commit_url]).to include "?merge_request_iid=3"
    end
  end
end
