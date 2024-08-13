# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RedirectRoute do
  let(:group) { create(:group) }
  let!(:redirect_route) { group.redirect_routes.create!(path: 'gitlabb') }

  describe 'relationships' do
    it { is_expected.to belong_to(:source) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_uniqueness_of(:path).case_insensitive }
  end

  describe '.for_source_type' do
    subject { described_class.for_source_type(source_type) }

    context 'when Project' do
      let(:source_type) { Project }

      it { is_expected.to be_empty }
    end

    context 'when Namespace' do
      let(:source_type) { Namespace }

      it { is_expected.to match_array(redirect_route) }
    end
  end

  describe '.by_paths' do
    subject { described_class.by_paths(paths) }

    let!(:redirect2) { group.redirect_routes.create!(path: 'gitlabb/test') }

    context 'when no matches' do
      let(:paths) { ['unknown'] }

      it { is_expected.to be_empty }
    end

    context 'when some matches' do
      let(:paths) { %w[unknown gitlabb] }

      it { is_expected.to match_array([redirect_route]) }
    end

    context 'when multiple matches' do
      let(:paths) { ['unknown', 'gitlabb', 'gitlabb/test'] }

      it { is_expected.to match_array([redirect_route, redirect2]) }
    end
  end

  describe '.matching_path_and_descendants' do
    let!(:redirect2) { group.redirect_routes.create!(path: 'gitlabb/test') }
    let!(:redirect3) { group.redirect_routes.create!(path: 'gitlabb/test/foo') }
    let!(:redirect4) { group.redirect_routes.create!(path: 'gitlabb/test/foo/bar') }
    let!(:redirect5) { group.redirect_routes.create!(path: 'gitlabb/test/baz') }

    context 'when the redirect route matches with same casing' do
      it 'returns correct routes' do
        expect(described_class.matching_path_and_descendants('gitlabb/test')).to match_array([redirect2, redirect3, redirect4, redirect5])
      end
    end

    context 'when the redirect route matches with different casing' do
      it 'returns correct routes' do
        expect(described_class.matching_path_and_descendants('GitLABB/test')).to match_array([redirect2, redirect3, redirect4, redirect5])
      end
    end
  end
end
