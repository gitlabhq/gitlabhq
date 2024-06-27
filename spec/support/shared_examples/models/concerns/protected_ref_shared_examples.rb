# frozen_string_literal: true

RSpec.shared_examples 'protected ref' do
  let_it_be(:factory) { described_class.model_name.singular }
  let_it_be(:project) { create(:project) }

  subject(:described_instance) { build(factory, project: project) }

  describe 'Associations' do
    it { is_expected.to belong_to(:project).touch(true) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'ref_matcher delegates' do
    subject(:ref_matcher) { described_class.new(name: ref_pattern) }

    describe '#matching' do
      it_behaves_like 'RefMatcher#matching'
    end

    describe '#matches?' do
      it_behaves_like 'RefMatcher#matches?'
    end

    describe '#wildcard?' do
      it_behaves_like 'RefMatcher#wildcard?'
    end
  end

  describe '#commit' do
    subject(:commit) { described_instance.commit }

    context 'when project is present' do
      context 'when a commit exists with the same name' do
        let(:branch) { project.default_branch }
        let(:head_commit) { project.commit }

        before do
          allow(described_instance).to receive(:name).and_return(branch)
        end

        it { is_expected.to eq(head_commit) }
      end

      context 'when a commit does not exist with the same name' do
        before do
          allow(described_instance).to receive(:name).and_return('thisisnotacommitid')
        end

        it { is_expected.to be_nil }
      end
    end

    context 'when project is nil' do
      let(:project) { nil }

      it { is_expected.to be_nil }
    end
  end
end
