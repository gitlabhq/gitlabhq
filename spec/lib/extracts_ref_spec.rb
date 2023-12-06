# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExtractsRef, feature_category: :source_code_management do
  include described_class
  include RepoHelpers

  let_it_be(:owner) { create(:user) }
  let_it_be(:container) { create(:snippet, :repository, author: owner) }

  let(:ref) { sample_commit[:id] }
  let(:path) { sample_commit[:line_code_path] }
  let(:params) { ActionController::Parameters.new(path: path, ref: ref) }

  before do
    ref_names = ['master', 'foo/bar/baz', 'v1.0.0', 'v2.0.0', 'release/app', 'release/app/v1.0.0']

    allow(container.repository).to receive(:ref_names).and_return(ref_names)
    allow_any_instance_of(described_class).to receive(:repository_container).and_return(container)
  end

  describe '#assign_ref_vars' do
    it_behaves_like 'assigns ref vars'

    context 'ref and path are nil' do
      let(:ref) { nil }
      let(:path) { nil }

      it 'does not set commit' do
        expect(container.repository).not_to receive(:commit).with('')

        assign_ref_vars

        expect(@commit).to be_nil
      end
    end

    context 'when ref and path have incorrect format' do
      let(:ref) { { wrong: :format } }
      let(:path) { { also: :wrong } }

      it 'does not raise an exception' do
        expect { assign_ref_vars }.not_to raise_error
      end
    end

    context 'when a ref_type parameter is provided' do
      let(:params) { ActionController::Parameters.new(path: path, ref: ref, ref_type: 'tags') }

      it 'sets a fully_qualified_ref variable' do
        fully_qualified_ref = "refs/tags/#{ref}"
        expect(container.repository).to receive(:commit).with(fully_qualified_ref)
        assign_ref_vars
        expect(@fully_qualified_ref).to eq(fully_qualified_ref)
      end
    end
  end

  describe '#ref_type' do
    let(:params) { ActionController::Parameters.new(ref_type: 'heads') }

    it 'delegates to .ref_type' do
      expect(described_class).to receive(:ref_type).with('heads')
      ref_type
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

    context 'when case does not match' do
      let(:ref_type) { 'tAgS' }

      it { is_expected.to(eq('tags')) }
    end

    context 'when ref_type is invalid' do
      let(:ref_type) { 'invalid' }

      it { is_expected.to eq(nil) }
    end

    context 'when ref_type is a hash' do
      let(:ref_type) { { 'just' => 'hash' } }

      it { is_expected.to eq(nil) }
    end
  end

  it_behaves_like 'extracts refs'
end
