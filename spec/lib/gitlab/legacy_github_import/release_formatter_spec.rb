require 'spec_helper'

describe Gitlab::LegacyGithubImport::ReleaseFormatter do
  let!(:project) { create(:project, namespace: create(:namespace, path: 'octocat')) }
  let(:octocat) { double(id: 123456, login: 'octocat') }
  let(:created_at) { DateTime.strptime('2011-01-26T19:01:12Z') }

  let(:base_data) do
    {
      tag_name: 'v1.0.0',
      name: 'First release',
      draft: false,
      created_at: created_at,
      published_at: created_at,
      body: 'Release v1.0.0'
    }
  end

  subject(:release) { described_class.new(project, raw_data) }

  describe '#attributes' do
    let(:raw_data) { double(base_data) }

    it 'returns formatted attributes' do
      expected = {
        project: project,
        tag: 'v1.0.0',
        description: 'Release v1.0.0',
        created_at: created_at,
        updated_at: created_at
      }

      expect(release.attributes).to eq(expected)
    end
  end

  describe '#valid' do
    context 'when release is not a draft' do
      let(:raw_data) { double(base_data) }

      it 'returns true' do
        expect(release.valid?).to eq true
      end
    end

    context 'when release is draft' do
      let(:raw_data) { double(base_data.merge(draft: true)) }

      it 'returns false' do
        expect(release.valid?).to eq false
      end
    end
  end
end
