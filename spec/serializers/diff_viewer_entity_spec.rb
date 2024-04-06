# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffViewerEntity, feature_category: :code_review_workflow do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff_refs) { commit.diff_refs }
  let(:diff) { commit.raw_diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: diff_refs, repository: repository) }
  let(:viewer) { diff_file.simple_viewer }
  let(:options) { {} }

  subject { described_class.new(viewer).as_json(options) }

  it 'serializes diff file viewer' do
    expect(subject.with_indifferent_access).to match_schema('entities/diff_viewer')
  end

  it 'contains whitespace_only attribute' do
    expect(subject.with_indifferent_access).to include(:whitespace_only)
  end

  context 'when whitespace_only option is true' do
    let(:options) { { whitespace_only: true } }

    it 'returns the whitespace_only attribute true' do
      expect(subject.with_indifferent_access[:whitespace_only]).to eq true
    end
  end

  context 'when whitespace_only option is false' do
    let(:options) { { whitespace_only: false } }

    it 'returns the whitespace_only attribute false' do
      expect(subject.with_indifferent_access[:whitespace_only]).to eq false
    end
  end
end
