# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExtractsRef::VerifiedRefExtractor, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }

  let(:ref) { 'ref' }
  let(:ref_type) { nil }

  # Create branches and tags consistently with the same shas to make comparison easier to follow
  let(:tag_sha) { RepoHelpers.sample_commit.id }
  let(:tag_name) { ref }
  let(:branch_sha) { RepoHelpers.another_sample_commit.id }
  let(:branch_name) { ref }
  let(:commit_sha) { project.repository.commit.sha }

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

  describe '#ambiguous_ref?' do
    subject { described_class.new(project.repository, ref_type: ref_type, ref: ref).ambiguous_ref? }

    context 'when ref_type is specified' do
      %w[heads tags HeAdS].each do |ref_type|
        context "with ref_type #{ref_type}" do
          let(:ref_type) { ref_type }

          it { is_expected.to be(false) }
        end
      end
    end

    context 'when the ref is the sha for a commit' do
      let(:ref) { project.repository.commit.sha }

      it { is_expected.to be(false) }

      context 'and a tag exists' do
        include_context 'when a tag exists'

        it { is_expected.to be(false) }

        context 'and a branch exists' do
          include_context 'when a branch exists'

          it { is_expected.to be(false) }
        end
      end

      context 'and a branch exists' do
        include_context 'when a branch exists'

        it { is_expected.to be(false) }
      end
    end

    context 'when the ref is a short sha for a commit' do
      # Git stops recognising short SHAs as commit OIDs if a branch or tag is
      # named exactly the same.
      let(:ref) { project.repository.commit.sha[..7] }

      it { is_expected.to be(false) }

      context 'and a tag exists' do
        include_context 'when a tag exists'

        it { is_expected.to be(false) }

        context 'and a branch exists' do
          include_context 'when a branch exists'

          it { is_expected.to be(true) }
        end
      end

      context 'and a branch exists' do
        include_context 'when a branch exists'

        it { is_expected.to be(false) }
      end
    end

    context 'when ref is for a tag' do
      let(:ref) { SecureRandom.uuid }

      include_context 'when a tag exists'

      it { is_expected.to be(false) }

      context 'and a branch exists' do
        include_context 'when a branch exists'

        it { is_expected.to be(true) }
      end
    end

    context 'when ref is for a branch' do
      let(:ref) { SecureRandom.uuid }

      include_context 'when a branch exists'

      it { is_expected.to be(false) }
    end

    context 'when ref is an abbreviated commit sha' do
      let(:ref) { branch_sha.first(8) }

      it { is_expected.to be(false) }
    end

    context 'when ref does not exist' do
      let(:ref) { SecureRandom.uuid }

      it { is_expected.to be(false) }
    end

    context 'when ref is symbolic' do
      let(:ref) { "heads/#{branch_name}" }
      let(:branch_name) { SecureRandom.uuid }

      include_context 'when a branch exists'

      it { is_expected.to be(true) }
    end
  end

  describe '#ref_type' do
    subject { described_class.new(project.repository, ref_type: ref_type, ref: ref).ref_type }

    describe 'when ref_type is defined' do
      where(:ref_type, :expectation) do
        [
          %w[heads heads],
          %w[tags tags],
          %w[HeAdS heads],
          [lazy { project.repository.commit.sha }, nil],
          ['invalid', nil],
          [' ', nil]
        ]
      end

      with_them do
        it { is_expected.to eq(expectation) }
      end
    end

    describe 'when ref_type is blank' do
      context 'when ref ambiguously matches' do
        context 'with a tag' do
          include_context 'when a tag exists'

          context 'and a branch' do
            include_context 'when a branch exists'

            it { is_expected.to be_nil }
          end

          context 'and a commit' do
            let(:ref) { commit_sha }

            it { is_expected.to be_nil }
          end
        end

        context 'with a branch and a commit' do
          let(:ref) { commit_sha }

          include_context 'when a branch exists'

          it { is_expected.to be_nil }
        end
      end

      context 'when ref is a tag' do
        include_context 'when a tag exists'

        it { is_expected.to eq('tags') }
      end

      context 'when ref is a branch' do
        include_context 'when a branch exists'

        it { is_expected.to eq('heads') }
      end

      context 'when ref is a commit' do
        let(:ref) { commit_sha }

        it { is_expected.to be_nil }
      end
    end
  end
end
