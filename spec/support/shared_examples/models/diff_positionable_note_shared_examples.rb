# frozen_string_literal: true

shared_examples_for 'a valid diff positionable note' do |factory_on_commit|
  context 'for commit' do
    let(:project) { create(:project, :repository) }
    let(:commit) { project.commit(sample_commit.id) }
    let(:commit_id) { commit.id }
    let(:diff_refs) { commit.diff_refs }

    let(:position) do
      Gitlab::Diff::Position.new(
        old_path: "files/ruby/popen.rb",
        new_path: "files/ruby/popen.rb",
        old_line: nil,
        new_line: 14,
        diff_refs: diff_refs
      )
    end

    subject { build(factory_on_commit, commit_id: commit_id, position: position) }

    context 'position diff refs matches commit diff refs' do
      it 'is valid' do
        expect(subject).to be_valid
        expect(subject.errors).not_to have_key(:commit_id)
      end
    end

    context 'position diff refs does not match commit diff refs' do
      let(:diff_refs) do
        Gitlab::Diff::DiffRefs.new(
          base_sha: "not_existing_sha",
          head_sha: "existing_sha"
        )
      end

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors).to have_key(:commit_id)
      end
    end

    context 'commit does not exist' do
      let(:commit_id) { 'non-existing' }

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors).to have_key(:commit_id)
      end
    end
  end
end
