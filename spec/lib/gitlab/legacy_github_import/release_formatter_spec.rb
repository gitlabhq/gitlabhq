# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::ReleaseFormatter do
  let_it_be(:project) { create(:project, :with_import_url, :import_user_mapping_enabled) }

  let(:octocat) { { id: 123456, login: 'octocat' } }
  let(:created_at) { DateTime.strptime('2011-01-26T19:01:12Z') }
  let(:published_at) { DateTime.strptime('2011-01-26T20:00:00Z') }

  let(:base_data) do
    {
      tag_name: 'v1.0.0',
      name: 'First release',
      draft: false,
      created_at: created_at,
      published_at: published_at,
      body: 'Release v1.0.0'
    }
  end

  subject(:release) { described_class.new(project, raw_data) }

  describe '#attributes' do
    let(:raw_data) { base_data }

    it 'returns formatted attributes' do
      expected = {
        project: project,
        tag: 'v1.0.0',
        name: 'First release',
        description: 'Release v1.0.0',
        created_at: created_at,
        released_at: published_at,
        updated_at: created_at
      }

      expect(release.attributes).to eq(expected)
    end

    context 'with a nil published_at date' do
      let(:published_at) { nil }

      it 'inserts a timestamp for released_at' do
        expect(release.attributes[:released_at]).to be_a(Time)
      end
    end
  end

  describe '#valid' do
    context 'when release is not a draft' do
      let(:raw_data) { base_data }

      it 'returns true' do
        expect(release.valid?).to eq true
      end
    end

    context 'when release is draft' do
      let(:raw_data) { base_data.merge(draft: true) }

      it 'returns false' do
        expect(release.valid?).to eq false
      end
    end

    context 'when release has NULL tag' do
      let(:raw_data) { base_data.merge(tag_name: '') }

      it 'returns false' do
        expect(release.valid?).to eq false
      end
    end
  end
end
