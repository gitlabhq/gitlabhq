# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ExternalPullRequest, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }

  let(:source_branch) { 'the-branch' }
  let(:status) { :open }

  it { is_expected.to belong_to(:project) }

  shared_examples 'has errors on' do |attribute|
    it "has errors for #{attribute}" do
      expect(subject).not_to be_valid
      expect(subject.errors[attribute]).not_to be_empty
    end
  end

  describe 'validations' do
    context 'when source branch not present' do
      subject { build(:external_pull_request, source_branch: nil) }

      it_behaves_like 'has errors on', :source_branch
    end

    context 'when status not present' do
      subject { build(:external_pull_request, status: nil) }

      it_behaves_like 'has errors on', :status
    end

    context 'when pull request is from a fork' do
      subject { build(:external_pull_request, source_repository: 'the-fork', target_repository: 'the-target') }

      it_behaves_like 'has errors on', :base
    end
  end

  describe 'create_or_update_from_params' do
    subject { described_class.create_or_update_from_params(params) }

    context 'when pull request does not exist' do
      context 'when params are correct' do
        let(:params) do
          {
            project_id: project.id,
            pull_request_iid: 123,
            source_branch: 'feature',
            target_branch: 'master',
            source_repository: 'the-repository',
            target_repository: 'the-repository',
            source_sha: '97de212e80737a608d939f648d959671fb0a0142',
            target_sha: 'a09386439ca39abe575675ffd4b89ae824fec22f',
            status: :open
          }
        end

        it 'saves the model successfully and returns it' do
          expect(subject).to be_persisted
          expect(subject).to be_valid
        end

        it 'yields the model' do
          yielded_value = nil

          result = described_class.create_or_update_from_params(params) do |pull_request|
            yielded_value = pull_request
          end

          expect(result).to eq(yielded_value)
        end
      end

      context 'when params are not correct' do
        let(:params) do
          {
            pull_request_iid: 123,
            source_branch: 'feature',
            target_branch: 'master',
            source_repository: 'the-repository',
            target_repository: 'the-repository',
            source_sha: nil,
            target_sha: nil,
            status: :open
          }
        end

        it 'returns an invalid model' do
          expect(subject).not_to be_persisted
          expect(subject).not_to be_valid
        end
      end
    end

    context 'when pull request exists' do
      let!(:pull_request) do
        create(:external_pull_request,
          project: project,
          source_sha: '97de212e80737a608d939f648d959671fb0a0142')
      end

      context 'when params are correct' do
        let(:params) do
          {
            pull_request_iid: pull_request.pull_request_iid,
            source_branch: pull_request.source_branch,
            target_branch: pull_request.target_branch,
            source_repository: 'the-repository',
            target_repository: 'the-repository',
            source_sha: 'ce84140e8b878ce6e7c4d298c7202ff38170e3ac',
            target_sha: pull_request.target_sha,
            status: :open
          }
        end

        it 'updates the model successfully and returns it' do
          expect(subject).to be_valid
          expect(subject.source_sha).to eq(params[:source_sha])
          expect(pull_request.reload.source_sha).to eq(params[:source_sha])
        end
      end

      context 'when params are not correct' do
        let(:params) do
          {
            pull_request_iid: pull_request.pull_request_iid,
            source_branch: pull_request.source_branch,
            target_branch: pull_request.target_branch,
            source_repository: 'the-repository',
            target_repository: 'the-repository',
            source_sha: nil,
            target_sha: nil,
            status: :open
          }
        end

        it 'returns an invalid model' do
          expect(subject).not_to be_valid
          expect(pull_request.reload.source_sha).not_to be_nil
          expect(pull_request.target_sha).not_to be_nil
        end
      end
    end
  end

  describe '#open?' do
    it 'returns true if status is open' do
      pull_request = create(:external_pull_request, status: :open)

      expect(pull_request).to be_open
    end

    it 'returns false if status is not open' do
      pull_request = create(:external_pull_request, status: :closed)

      expect(pull_request).not_to be_open
    end
  end

  describe '#closed?' do
    it 'returns true if status is closed' do
      pull_request = build(:external_pull_request, status: :closed)

      expect(pull_request).to be_closed
    end

    it 'returns false if status is not closed' do
      pull_request = build(:external_pull_request, status: :open)

      expect(pull_request).not_to be_closed
    end
  end

  describe '#actual_branch_head?' do
    let(:project) { create(:project, :repository) }
    let(:branch) { project.repository.branches.first }
    let(:source_branch) { branch.name }

    let(:pull_request) do
      create(:external_pull_request,
        project: project,
        source_branch: source_branch,
        source_sha: source_sha)
    end

    context 'when source sha matches the head of the branch' do
      let(:source_sha) { branch.target }

      it 'returns true' do
        expect(pull_request).to be_actual_branch_head
      end
    end

    context 'when source sha does not match the head of the branch' do
      let(:source_sha) { project.repository.commit('HEAD').sha }

      it 'returns true' do
        expect(pull_request).not_to be_actual_branch_head
      end
    end
  end

  describe '#from_fork?' do
    it 'returns true if source_repository differs from target_repository' do
      pull_request = build(:external_pull_request,
        source_repository: 'repository-1',
        target_repository: 'repository-2')

      expect(pull_request).to be_from_fork
    end

    it 'returns false if source_repository is the same as target_repository' do
      pull_request = build(:external_pull_request,
        source_repository: 'repository-1',
        target_repository: 'repository-1')

      expect(pull_request).not_to be_from_fork
    end
  end

  describe '#modified_paths' do
    let(:pull_request) do
      build(:external_pull_request, project: project, target_sha: '281d3a7', source_sha: '498214d')
    end

    subject(:modified_paths) { pull_request.modified_paths }

    it 'returns modified paths' do
      expect(modified_paths).to eq ['bar/branch-test.txt',
        'files/js/commit.coffee',
        'with space/README.md']
    end
  end

  describe '#changed_paths' do
    let(:pull_request) do
      build(:external_pull_request, project: project, target_sha: '281d3a7', source_sha: '498214d')
    end

    subject(:changed_paths) { pull_request.changed_paths }

    it 'returns modified paths' do
      expect(changed_paths.as_json).to eq [
        Gitlab::Git::ChangedPath.new(
          new_blob_id: "93e123ac8a3e6a0b600953d7598af629dec7b735",
          new_mode: "100644",
          old_blob_id: "0000000000000000000000000000000000000000",
          old_mode: "0",
          old_path: "bar/branch-test.txt",
          path: "bar/branch-test.txt",
          status: :ADDED,
          commit_id: ""
        ),
        Gitlab::Git::ChangedPath.new(
          new_blob_id: "85bc2f9753afd5f4fc5d7c75f74f8d526f26b4f3",
          new_mode: "100644",
          old_blob_id: "0000000000000000000000000000000000000000",
          old_mode: "0",
          old_path: "files/js/commit.coffee",
          path: "files/js/commit.coffee",
          status: :ADDED,
          commit_id: ""
        ),
        Gitlab::Git::ChangedPath.new(
          new_blob_id: "0000000000000000000000000000000000000000",
          new_mode: "0",
          old_blob_id: "5f53439ca4b009096571d3c8bc3d09d30e7431b3",
          old_mode: "100644",
          old_path: "files/js/commit.js.coffee",
          path: "files/js/commit.js.coffee",
          status: :DELETED,
          commit_id: ""
        ),
        Gitlab::Git::ChangedPath.new(
          new_blob_id: "8c3014aceae45386c3c026a7ea4a1f68660d51d6",
          new_mode: "100644",
          old_blob_id: "0000000000000000000000000000000000000000",
          old_mode: "0",
          old_path: "with space/README.md",
          path: "with space/README.md",
          status: :ADDED,
          commit_id: ""
        )
      ].as_json
    end
  end

  context 'with a loose foreign key on external_pull_requests.project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project) }
      let!(:model) { create(:external_pull_request, project: parent) }
    end
  end
end
