# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranch::CacheKey, feature_category: :source_code_management do
  subject(:cache_key) { described_class.new(entity) }

  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  describe '#to_s' do
    subject { cache_key.to_s }

    context 'with entity project' do
      let(:entity) { project }

      it 'returns a scoped key' do
        is_expected.to eq "cache:gitlab:protected_branch:project:#{project.id}"
      end

      context 'when a project presenter is provided' do
        let(:entity) { ProjectPresenter.new(project) }

        it 'returns the same key as a project' do
          is_expected.to eq "cache:gitlab:protected_branch:project:#{project.id}"
        end
      end
    end

    context 'with entity group' do
      let(:entity) { group }

      it 'returns a scoped key' do
        is_expected.to eq "cache:gitlab:protected_branch:group:#{group.id}"
      end
    end

    context 'with an unsupported entity' do
      let(:entity) { user }

      it 'returns a scoped key' do
        is_expected.to eq "cache:gitlab:protected_branch:user:#{user.id}"
      end
    end
  end
end
