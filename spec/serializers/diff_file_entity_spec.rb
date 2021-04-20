# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffFileEntity do
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }

  let(:repository) { project.repository }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff_refs) { commit.diff_refs }
  let(:diff) { commit.raw_diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: diff_refs, repository: repository) }
  let(:options) { {} }
  let(:entity) { described_class.new(diff_file, options.reverse_merge(request: {})) }

  subject { entity.as_json }

  context 'when there is no merge request' do
    it_behaves_like 'diff file entity'
  end

  context 'when there is a merge request' do
    let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

    let(:user) { create(:user) }
    let(:code_navigation_path) { Gitlab::CodeNavigationPath.new(project, project.commit.sha) }
    let(:request) { EntityRequest.new(project: project, current_user: user) }
    let(:entity) { described_class.new(diff_file, options.merge(request: request, merge_request: merge_request, code_navigation_path: code_navigation_path)) }
    let(:exposed_urls) { %i(edit_path view_path context_lines_path) }

    it_behaves_like 'diff file entity'

    it 'exposes additional attributes' do
      expect(subject).to include(*exposed_urls)
      expect(subject).to include(:replaced_view_path)
      expect(subject).to include(:code_navigation_path)
    end

    it 'points all urls to merge request target project' do
      response = subject

      exposed_urls.each do |attribute|
        expect(response[attribute]).to include(merge_request.target_project.to_param)
      end
    end

    it 'exposes load_collapsed_diff_url if the file viewer is collapsed' do
      allow(diff_file.viewer).to receive(:collapsed?) { true }

      expect(subject).to include(:load_collapsed_diff_url)
    end

    context 'when diff_view is unknown' do
      let(:options) { { diff_view: :unknown } }

      it 'hides highlighted_diff_lines and parallel_diff_lines' do
        is_expected.not_to include(:highlighted_diff_lines, :parallel_diff_lines)
      end
    end
  end

  describe '#parallel_diff_lines' do
    let(:options) { { diff_view: :parallel } }

    it 'exposes parallel diff lines correctly' do
      response = subject

      lines = response[:parallel_diff_lines]

      # make sure at least one line is present for each side
      expect(lines.map { |line| line[:right] }.compact).to be_present
      expect(lines.map { |line| line[:left] }.compact).to be_present
      # make sure all lines are in correct format
      lines.each do |parallel_line|
        expect(parallel_line[:left].as_json).to match_schema('entities/diff_line') if parallel_line[:left]
        expect(parallel_line[:right].as_json).to match_schema('entities/diff_line') if parallel_line[:right]
      end
    end
  end

  describe '#is_fully_expanded' do
    context 'file with a conflict' do
      let(:options) { { conflicts: { diff_file.new_path => double(diff_lines_for_serializer: []) } } }

      it 'returns false' do
        expect(diff_file).not_to receive(:fully_expanded?)
        expect(subject[:is_fully_expanded]).to eq(false)
      end
    end
  end
end
