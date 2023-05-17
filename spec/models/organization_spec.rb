# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organization, type: :model, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:default_organization) { create(:organization, :default) }

  describe 'validations' do
    subject { create(:organization) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
  end

  context 'when using scopes' do
    describe '.without_default' do
      it 'excludes default organization' do
        expect(described_class.without_default).not_to include(default_organization)
      end

      it 'includes other organizations organization' do
        expect(described_class.without_default).to include(organization)
      end
    end
  end

  describe '#id' do
    context 'when organization is default' do
      it 'has id 1' do
        expect(default_organization.id).to eq(1)
      end
    end

    context 'when organization is not default' do
      it 'does not have id 1' do
        expect(organization.id).not_to eq(1)
      end
    end
  end

  describe '#destroy!' do
    context 'when trying to delete the default organization' do
      it 'raises an error' do
        expect do
          default_organization.destroy!
        end.to raise_error(ActiveRecord::RecordNotDestroyed, _('Cannot delete the default organization'))
      end
    end

    context 'when trying to delete a non-default organization' do
      let(:to_be_removed) { create(:organization) }

      it 'does not raise error' do
        expect { to_be_removed.destroy! }.not_to raise_error
      end
    end
  end

  describe '#destroy' do
    context 'when trying to delete the default organization' do
      it 'returns false' do
        expect(default_organization.destroy).to eq(false)
      end
    end

    context 'when trying to delete a non-default organization' do
      let(:to_be_removed) { create(:organization) }

      it 'returns true' do
        expect(to_be_removed.destroy).to eq(to_be_removed)
      end
    end
  end

  describe '#default?' do
    context 'when organization is default' do
      it 'returns true' do
        expect(default_organization.default?).to eq(true)
      end
    end

    context 'when organization is not default' do
      it 'returns false' do
        expect(organization.default?).to eq(false)
      end
    end
  end

  describe '#name' do
    context 'when organization is default' do
      it 'returns Default' do
        expect(default_organization.name).to eq('Default')
      end
    end
  end
end
