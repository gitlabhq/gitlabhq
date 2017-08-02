require 'spec_helper'

describe Gitlab::Diff::DiffRefs do
  let(:project) { create(:project, :repository) }

  describe '#compare_in' do
    context 'with diff refs for the initial commit' do
      let(:commit) { project.commit('1a0b36b3cdad1d2ee32457c102a8c0b7056fa863') }
      subject { commit.diff_refs }

      it 'returns an appropriate comparison' do
        compare = subject.compare_in(project)

        expect(compare.diff_refs).to eq(subject)
      end
    end

    context 'with diff refs for a commit' do
      let(:commit) { project.commit('6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
      subject { commit.diff_refs }

      it 'returns an appropriate comparison' do
        compare = subject.compare_in(project)

        expect(compare.diff_refs).to eq(subject)
      end
    end

    context 'with diff refs for a comparison through the base' do
      subject do
        described_class.new(
          start_sha: '0b4bc9a49b562e85de7cc9e834518ea6828729b9', # feature
          base_sha: 'ae73cb07c9eeaf35924a10f713b364d32b2dd34f',
          head_sha: 'e63f41fe459e62e1228fcef60d7189127aeba95a' # master
        )
      end

      it 'returns an appropriate comparison' do
        compare = subject.compare_in(project)

        expect(compare.diff_refs).to eq(subject)
      end
    end

    context 'with diff refs for a straight comparison' do
      subject do
        described_class.new(
          start_sha: '0b4bc9a49b562e85de7cc9e834518ea6828729b9', # feature
          base_sha: '0b4bc9a49b562e85de7cc9e834518ea6828729b9',
          head_sha: 'e63f41fe459e62e1228fcef60d7189127aeba95a' # master
        )
      end

      it 'returns an appropriate comparison' do
        compare = subject.compare_in(project)

        expect(compare.diff_refs).to eq(subject)
      end
    end
  end
end
