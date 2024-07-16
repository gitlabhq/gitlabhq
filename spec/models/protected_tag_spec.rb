# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedTag, feature_category: :source_code_management do
  it_behaves_like 'protected ref', :protected_tag
  it_behaves_like 'protected ref with access levels for', :create

  describe 'Associations' do
    it { is_expected.to belong_to(:project).touch(true) }
    it { is_expected.to have_many(:create_access_levels).inverse_of(:protected_tag) }
  end

  describe 'Validation' do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe '#protected?' do
    let(:project) { create(:project, :repository) }

    it 'returns true when the tag matches a protected tag via direct match' do
      create(:protected_tag, project: project, name: 'foo')

      expect(described_class.protected?(project, 'foo')).to eq(true)
    end

    it 'returns true when the tag matches a protected tag via wildcard match' do
      create(:protected_tag, project: project, name: 'production/*')

      expect(described_class.protected?(project, 'production/some-tag')).to eq(true)
    end

    it 'returns false when the tag does not match a protected tag via direct match' do
      expect(described_class.protected?(project, 'foo')).to eq(false)
    end

    it 'returns false when the tag does not match a protected tag via wildcard match' do
      create(:protected_tag, project: project, name: 'production/*')

      expect(described_class.protected?(project, 'staging/some-tag')).to eq(false)
    end

    it 'returns false when tag name is nil' do
      expect(described_class.protected?(project, nil)).to eq(false)
    end

    context 'with caching', :request_store do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:protected_tag) { create(:protected_tag, project: project, name: 'foo') }

      it 'correctly invalidates a cache' do
        expect(described_class.protected?(project, 'foo')).to eq(true)
        expect(described_class.protected?(project, 'bar')).to eq(false)

        create(:protected_tag, project: project, name: 'bar')

        expect(described_class.protected?(project, 'bar')).to eq(true)
      end

      it 'correctly uses the cached version' do
        expect(project).to receive(:protected_tags).once.and_call_original

        2.times do
          expect(described_class.protected?(project, protected_tag.name)).to eq(true)
        end
      end
    end
  end
end
