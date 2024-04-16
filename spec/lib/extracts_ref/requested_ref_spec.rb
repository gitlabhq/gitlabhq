# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExtractsRef::RequestedRef, feature_category: :source_code_management do
  describe '#find' do
    subject { described_class.new(project.repository, ref_type: ref_type, ref: ref).find }

    let_it_be(:project) { create(:project, :repository) }
    let(:ref_type) { nil }

    # Create branches and tags consistently with the same shas to make comparison easier to follow
    let(:tag_sha) { RepoHelpers.sample_commit.id }
    let(:branch_sha) { RepoHelpers.another_sample_commit.id }

    shared_context 'when a branch exists' do
      before do
        project.repository.create_branch(branch_name, branch_sha)
        project.repository.expire_branches_cache
      end

      after do
        project.repository.rm_branch(project.owner, branch_name)
      end
    end

    shared_context 'when a tag exists' do
      before do
        project.repository.add_tag(project.owner, tag_name, tag_sha)
        project.repository.expire_tags_cache
      end

      after do
        project.repository.rm_tag(project.owner, tag_name)
      end
    end

    shared_examples 'RequestedRef when ref_type is specified' do |branch_sha, tag_sha|
      context 'when ref_type is heads' do
        let(:ref_type) { 'heads' }

        it 'returns the branch commit' do
          expect(subject[:ref_type]).to eq('heads')
          expect(subject[:commit].id).to eq(branch_sha)
        end
      end

      context 'when ref_type is tags' do
        let(:ref_type) { 'tags' }

        it 'returns the tag commit' do
          expect(subject[:ref_type]).to eq('tags')
          expect(subject[:commit].id).to eq(tag_sha)
        end
      end
    end

    context 'when the ref is the sha for a commit' do
      let(:ref) { branch_sha }

      context 'and a tag and branch with that sha as a name' do
        include_context 'when a branch exists' do
          let(:branch_name) { ref }
        end

        include_context 'when a tag exists' do
          let(:tag_name) { ref }
        end

        it_behaves_like 'RequestedRef when ref_type is specified',
          RepoHelpers.another_sample_commit.id,
          RepoHelpers.sample_commit.id

        it 'returns the commit' do
          expect(subject[:ref_type]).to be_nil
          expect(subject[:commit].id).to eq(ref)
        end
      end
    end

    context 'when ref is for a tag' do
      include_context 'when a tag exists' do
        let(:tag_name) { SecureRandom.uuid }
      end

      let(:ref) { tag_name }

      it 'returns the tag commit' do
        expect(subject[:ref_type]).to eq('tags')
        expect(subject[:commit].id).to eq(tag_sha)
      end

      context 'when branch is missing' do
        it 'does not call FindBranch for performance reasons' do
          expect(project.repository).not_to receive(:find_branch)

          expect(subject[:ref_type]).to eq('tags')
          expect(subject[:commit].id).to eq(tag_sha)
        end
      end

      context 'and there is a branch with the same name' do
        include_context 'when a branch exists' do
          let(:branch_name) { ref }
        end

        it_behaves_like 'RequestedRef when ref_type is specified',
          RepoHelpers.another_sample_commit.id,
          RepoHelpers.sample_commit.id

        it 'returns the tag commit' do
          expect(subject[:ref_type]).to eq('tags')
          expect(subject[:commit].id).to eq(tag_sha)
          expect(subject[:ambiguous]).to be_truthy
        end
      end
    end

    context 'when ref is only for a branch' do
      let(:ref) { SecureRandom.uuid }

      include_context 'when a branch exists' do
        let(:branch_name) { ref }
      end

      it 'returns the branch commit' do
        expect(subject[:ref_type]).to eq('heads')
        expect(subject[:commit].id).to eq(branch_sha)
      end

      context 'when tag is missing' do
        it 'does not call FindTag for performance reasons' do
          expect(project.repository).not_to receive(:find_tag)

          expect(subject[:ref_type]).to eq('heads')
          expect(subject[:commit].id).to eq(branch_sha)
        end
      end
    end

    context 'when ref is an abbreviated commit sha' do
      let(:ref) { branch_sha.first(8) }

      it 'returns the commit' do
        expect(subject[:ref_type]).to be_nil
        expect(subject[:commit].id).to eq(branch_sha)
      end
    end

    context 'when ref does not exist' do
      let(:ref) { SecureRandom.uuid }

      it 'returns the commit' do
        expect(subject[:ref_type]).to be_nil
        expect(subject[:commit]).to be_nil
      end
    end

    context 'when ref is symbolic' do
      let(:ref) { "heads/#{branch_name}" }

      include_context 'when a branch exists' do
        let(:branch_name) { SecureRandom.uuid }
      end

      it 'returns the commit' do
        expect(subject[:ref_type]).to be_nil
        expect(subject[:commit].id).to eq(branch_sha)
        expect(subject[:ambiguous]).to be_truthy
      end
    end
  end
end
