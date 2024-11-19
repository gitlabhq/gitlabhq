# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ContributionsMapper, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:project) { create(:project, :with_import_url) }

  let(:mapper) { described_class.new(project) }

  let(:user_mapping_enabled) { true }

  before do
    project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: user_mapping_enabled })
  end

  describe '#user_mapper' do
    it 'creates an instance of a source user mapper' do
      expect(mapper.user_mapper).to be_an_instance_of(::Gitlab::Import::SourceUserMapper)
    end
  end

  describe '#user_mapping_enabled?' do
    context 'when user mapping is enabled' do
      it 'returns true' do
        expect(mapper.user_mapping_enabled?).to be true
      end
    end

    context 'when user mapping is disbled' do
      let(:user_mapping_enabled) { false }

      it 'returns false' do
        expect(mapper.user_mapping_enabled?).to be false
      end
    end
  end
end
