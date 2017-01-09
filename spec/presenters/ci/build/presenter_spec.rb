require 'spec_helper'

describe Ci::Build::Presenter do
  let(:project) { create(:empty_project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, pipeline: pipeline) }

  subject do
    described_class.new(build)
  end

  it 'inherits from Gitlab::View::Presenter::Delegated' do
    expect(described_class.superclass).to eq(Gitlab::View::Presenter::Delegated)
  end

  describe '#initialize' do
    it 'takes a build and optional params' do
      expect { subject }.not_to raise_error
    end

    it 'exposes build' do
      expect(subject.build).to eq(build)
    end

    it 'forwards missing methods to build' do
      expect(subject.ref).to eq('master')
    end
  end

  describe '#erased_by_user?' do
    it 'takes a build and optional params' do
      expect(subject).not_to be_erased_by_user
    end
  end

  describe '#erased_by_name' do
    context 'when build is not erased' do
      before do
        expect(build).to receive(:erased_by).and_return(nil)
      end

      it 'returns nil' do
        expect(subject.erased_by_name).to be_nil
      end
    end
    context 'when build is erased' do
      before do
        expect(build).to receive(:erased_by).twice.
          and_return(double(:user, name: 'John Doe'))
      end

      it 'returns the name of the eraser' do
        expect(subject.erased_by_name).to eq('John Doe')
      end
    end
  end

  describe 'quack like a Ci::Build permission-wise' do
    context 'user is not allowed' do
      let(:project) { create(:empty_project, public_builds: false) }

      it 'returns false' do
        expect(subject.can?(nil, :read_build)).to be_falsy
      end
    end

    context 'user is allowed' do
      let(:project) { create(:empty_project, :public) }

      it 'returns true' do
        expect(subject.can?(nil, :read_build)).to be_truthy
      end
    end
  end
end
