# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Tag, feature_category: :source_code_management do
  describe '#as_json' do
    subject { entity.as_json }

    let_it_be(:project) { create(:project, :public, :repository) }
    let_it_be(:repository) { project.repository }
    let_it_be(:user) { create(:user) }

    let(:tag) { repository.find_tag('v1.0.0') }
    let(:releases) { nil }
    let(:entity) { described_class.new(tag, project: project, releases: releases) }

    it 'includes basic fields', :aggregate_failures do
      is_expected.to include(
        name: 'v1.0.0',
        message: 'Release',
        target: 'f4e6814c3e4e7a0de82a9e7cd20c626cc963a2f8',
        commit: a_kind_of(Hash),
        release: nil,
        protected: false,
        created_at: a_kind_of(Time))
    end

    context 'when a tag is lightweight' do
      before do
        project.repository.add_tag(user, 'v1.2.3', 'master')
      end

      let(:tag) { repository.find_tag('v1.2.3') }

      it 'returns an empty created_at' do
        is_expected.to include(name: 'v1.2.3', created_at: nil)
      end
    end

    context 'with releases' do
      let(:release) { build(:release, tag: tag.name) }
      let(:releases) { [release] }

      it 'returns release details' do
        is_expected.to include(release: { tag_name: tag.name, description: release.description })
      end

      context 'when release tag name does not match' do
        let(:release) { build(:release, tag: 'unknown_tag') }

        it 'returns an empty release' do
          is_expected.to include(release: nil)
        end
      end
    end
  end
end
