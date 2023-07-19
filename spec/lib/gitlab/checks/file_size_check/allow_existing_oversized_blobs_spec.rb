# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::FileSizeCheck::AllowExistingOversizedBlobs, feature_category: :source_code_management do
  subject { checker.find }

  let_it_be(:project) { create(:project, :public, :repository) }
  let(:checker) do
    described_class.new(
      project: project,
      changes: changes,
      file_size_limit_megabytes: 1)
  end

  describe '#find' do
    let(:branch_name) { SecureRandom.uuid }
    let(:other_branch_name) { SecureRandom.uuid }
    let(:filename) { 'log.log' }
    let(:create_file) do
      project.repository.create_file(
        project.owner,
        filename,
        initial_contents,
        branch_name: branch_name,
        message: 'whatever'
      )
    end

    let(:changed_ref) do
      project.repository.update_file(
        project.owner,
        filename,
        changed_contents,
        branch_name: other_branch_name,
        start_branch_name: branch_name,
        message: 'whatever'
      )
    end

    let(:changes) { [oldrev: create_file, newrev: changed_ref] }

    before do
      # set up a branch
      create_file

      # branch off that branch
      changed_ref

      # delete stuff so it can be picked up by new_blobs
      project.repository.delete_branch(other_branch_name)
    end

    context 'when changing from valid to oversized' do
      let(:initial_contents) { 'a' }
      let(:changed_contents) { 'a' * ((2**20) + 1) } # 1 MB + 1 byte

      it 'returns an array with blobs that became oversized' do
        blob = subject.first
        expect(blob.path).to eq(filename)
        expect(subject).to contain_exactly(blob)
      end
    end

    context 'when changing from oversized to oversized' do
      let(:initial_contents) { 'a' * ((2**20) + 1) } # 1 MB + 1 byte
      let(:changed_contents) { 'a' * ((2**20) + 2) } # 1 MB + 1 byte

      it { is_expected.to be_blank }
    end

    context 'when changing from oversized to valid' do
      let(:initial_contents) { 'a' * ((2**20) + 1) } # 1 MB + 1 byte
      let(:changed_contents) { 'aa' }

      it { is_expected.to be_blank }
    end

    context 'when changing from valid to valid' do
      let(:initial_contents) { 'abc' }
      let(:changed_contents) { 'def' }

      it { is_expected.to be_blank }
    end
  end
end
