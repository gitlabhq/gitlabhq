require 'spec_helper'

describe BuildPresenter do
  let(:build) { create(:ci_build) }
  subject do
    described_class.new(build).with_subject(build)
  end

  describe '#initialize' do
    it 'takes a build and optional params' do
      expect { subject }.
        not_to raise_error
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

  describe 'quack like a Ci::Build' do
    it 'takes a build and optional params' do
      expect(described_class.ancestors).to include(Ci::Build)
    end
  end
end
