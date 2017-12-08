require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::Command do
  set(:project) { create(:project, :repository) }

  describe '#initialize' do
    subject do
      described_class.new(origin_ref: 'master')
    end

    it 'properly initialises object from hash' do
      expect(subject.origin_ref).to eq('master')
    end
  end

  context 'handling of origin_ref' do
    let(:command) { described_class.new(project: project, origin_ref: origin_ref) }

    describe '#branch_exists?' do
      subject { command.branch_exists? }

      context 'for existing branch' do
        let(:origin_ref) { 'master' }

        it { is_expected.to eq(true) }
      end

      context 'for invalid branch' do
        let(:origin_ref) { 'something' }

        it { is_expected.to eq(false) }
      end
    end

    describe '#tag_exists?' do
      subject { command.tag_exists? }

      context 'for existing ref' do
        let(:origin_ref) { 'v1.0.0' }

        it { is_expected.to eq(true) }
      end

      context 'for invalid ref' do
        let(:origin_ref) { 'something' }

        it { is_expected.to eq(false) }
      end
    end

    describe '#ref' do
      subject { command.ref }

      context 'for regular ref' do
        let(:origin_ref) { 'master' }

        it { is_expected.to eq('master') }
      end

      context 'for branch ref' do
        let(:origin_ref) { 'refs/heads/master' }

        it { is_expected.to eq('master') }
      end

      context 'for tag ref' do
        let(:origin_ref) { 'refs/tags/1.0.0' }

        it { is_expected.to eq('1.0.0') }
      end

      context 'for other refs' do
        let(:origin_ref) { 'refs/merge-requests/11/head' }

        it { is_expected.to eq('refs/merge-requests/11/head') }
      end
    end
  end

  describe '#sha' do
    subject { command.sha }

    context 'when invalid checkout_sha is specified' do
      let(:command) { described_class.new(project: project, checkout_sha: 'aaa') }

      it 'returns empty value' do
        is_expected.to be_nil
      end
    end

    context 'when a valid checkout_sha is specified' do
      let(:command) { described_class.new(project: project, checkout_sha: project.commit.id) }

      it 'returns checkout_sha' do
        is_expected.to eq(project.commit.id)
      end
    end

    context 'when a valid after_sha is specified' do
      let(:command) { described_class.new(project: project, after_sha: project.commit.id) }

      it 'returns after_sha' do
        is_expected.to eq(project.commit.id)
      end
    end

    context 'when a valid origin_ref is specified' do
      let(:command) { described_class.new(project: project, origin_ref: 'HEAD') }

      it 'returns SHA for given ref' do
        is_expected.to eq(project.commit.id)
      end
    end
  end

  describe '#origin_sha' do
    subject { command.origin_sha }

    context 'when using checkout_sha and after_sha' do
      let(:command) { described_class.new(project: project, checkout_sha: 'aaa', after_sha: 'bbb') }

      it 'uses checkout_sha' do
        is_expected.to eq('aaa')
      end
    end

    context 'when using after_sha only' do
      let(:command) { described_class.new(project: project, after_sha: 'bbb') }

      it 'uses after_sha' do
        is_expected.to eq('bbb')
      end
    end
  end

  describe '#before_sha' do
    subject { command.before_sha }

    context 'when using checkout_sha and before_sha' do
      let(:command) { described_class.new(project: project, checkout_sha: 'aaa', before_sha: 'bbb') }

      it 'uses before_sha' do
        is_expected.to eq('bbb')
      end
    end

    context 'when using checkout_sha only' do
      let(:command) { described_class.new(project: project, checkout_sha: 'aaa') }

      it 'uses checkout_sha' do
        is_expected.to eq('aaa')
      end
    end

    context 'when checkout_sha and before_sha are empty' do
      let(:command) { described_class.new(project: project) }

      it 'uses BLANK_SHA' do
        is_expected.to eq(Gitlab::Git::BLANK_SHA)
      end
    end
  end

  describe '#protected_ref?' do
    let(:command) { described_class.new(project: project, origin_ref: 'my-branch') }

    subject { command.protected_ref? }

    context 'when a ref is protected' do
      before do
        expect_any_instance_of(Project).to receive(:protected_for?).with('my-branch').and_return(true)
      end

      it { is_expected.to eq(true) }
    end

    context 'when a ref is unprotected' do
      before do
        expect_any_instance_of(Project).to receive(:protected_for?).with('my-branch').and_return(false)
      end

      it { is_expected.to eq(false) }
    end
  end
end
