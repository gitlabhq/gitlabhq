# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExtractsRef::RefExtractor, feature_category: :source_code_management do
  include RepoHelpers

  let_it_be(:owner) { create(:user) }
  let_it_be(:container) { create(:project_snippet, :repository, author: owner) }

  let(:ref) { sample_commit[:id] }
  let(:path) { sample_commit[:line_code_path] }
  let(:params) { { path: path, ref: ref } }

  let(:ref_extractor) { described_class.new(container, params) }

  before do
    ref_names = ['master', 'foo/bar/baz', 'v1.0.0', 'v2.0.0', 'release/app', 'release/app/v1.0.0']

    allow(container.repository).to receive(:ref_names).and_return(ref_names)
  end

  describe '#initialize' do
    let(:params) { { id: 1, ref: 2, path: 3, ref_type: 4 } }

    it 'does not mutate provided params' do
      ref_extractor

      expect(params).to eq(id: 1, ref: 2, path: 3, ref_type: 4)
    end
  end

  describe '#extract_vars!' do
    it_behaves_like 'extracts ref vars'

    context 'when ref contains trailing space' do
      let(:ref) { 'master ' }

      it 'strips surrounding space' do
        ref_extractor.extract!

        expect(ref_extractor.ref).to eq('master')
      end
    end

    context 'when ref and path are nil' do
      let(:ref) { nil }
      let(:path) { nil }

      it 'does not set commit' do
        expect(container.repository).not_to receive(:commit).with('')

        ref_extractor.extract!

        expect(ref_extractor.commit).to be_nil
      end
    end

    context 'when a ref_type parameter is provided' do
      let(:params) { { path: path, ref: ref, ref_type: 'tags' } }

      it 'sets a fully_qualified_ref variable' do
        fully_qualified_ref = "refs/tags/#{ref}"

        expect(container.repository).to receive(:commit).with(fully_qualified_ref)

        ref_extractor.extract!

        expect(ref_extractor.fully_qualified_ref).to eq(fully_qualified_ref)
      end
    end
  end

  describe '#ref_type' do
    let(:params) { { ref_type: 'heads' } }

    it 'delegates to .ref_type' do
      expect(described_class).to receive(:ref_type).with('heads')

      ref_extractor.ref_type
    end
  end

  describe '.ref_type' do
    subject { described_class.ref_type(ref_type) }

    context 'when ref_type is nil' do
      let(:ref_type) { nil }

      it { is_expected.to eq(nil) }
    end

    context 'when ref_type is heads' do
      let(:ref_type) { 'heads' }

      it { is_expected.to eq('heads') }
    end

    context 'when ref_type is tags' do
      let(:ref_type) { 'tags' }

      it { is_expected.to eq('tags') }
    end

    context 'when ref_type is invalid' do
      let(:ref_type) { 'invalid' }

      it { is_expected.to eq(nil) }
    end
  end

  describe '.qualify_ref' do
    subject { described_class.qualify_ref(ref, ref_type) }

    context 'when ref_type is nil' do
      let(:ref_type) { nil }

      it { is_expected.to eq(ref) }
    end

    context 'when ref_type valid' do
      let(:ref_type) { 'heads' }

      it { is_expected.to eq("refs/#{ref_type}/#{ref}") }
    end

    context 'when ref_type is invalid' do
      let(:ref_type) { 'invalid' }

      it { is_expected.to eq(ref) }
    end
  end

  it_behaves_like 'extracts ref method'
end
