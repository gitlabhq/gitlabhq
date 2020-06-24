# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffViewerEntity do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff_refs) { commit.diff_refs }
  let(:diff) { commit.raw_diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: diff_refs, repository: repository) }
  let(:viewer) { diff_file.simple_viewer }

  subject { described_class.new(viewer).as_json }

  it 'serializes diff file viewer' do
    expect(subject.with_indifferent_access).to match_schema('entities/diff_viewer')
  end
end
