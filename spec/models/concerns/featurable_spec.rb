# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Featurable do
  let!(:klass) do
    Class.new(ApplicationRecord) do
      include Featurable

      self.table_name = 'project_features'

      set_available_features %i[feature1 feature2 feature3]

      def feature1_access_level
        Featurable::DISABLED
      end

      def feature2_access_level
        Featurable::ENABLED
      end

      def feature3_access_level
        Featurable::PRIVATE
      end
    end
  end

  subject { klass.new }

  describe '.set_available_features' do
    it { expect(klass.available_features).to match_array [:feature1, :feature2, :feature3] }
  end

  describe '#*_enabled?' do
    it { expect(subject.feature1_enabled?).to be_falsey }
    it { expect(subject.feature2_enabled?).to be_truthy }
  end

  describe '.quoted_access_level_column' do
    it 'returns the table name and quoted column name for a feature' do
      expect(klass.quoted_access_level_column(:feature1)).to eq('"project_features"."feature1_access_level"')
    end
  end

  describe '.access_level_attribute' do
    it { expect(klass.access_level_attribute(:feature1)).to eq :feature1_access_level }

    it 'raises error for unspecified feature' do
      expect { klass.access_level_attribute(:unknown) }
        .to raise_error(ArgumentError, /invalid feature: unknown/)
    end
  end

  describe '#access_level' do
    it 'returns access level' do
      expect(subject.access_level(:feature1)).to eq(subject.feature1_access_level)
    end
  end

  describe '#feature_available?' do
    context 'when features are disabled' do
      it 'returns false' do
        expect(subject.feature_available?(:feature1)).to eq(false)
      end
    end

    context 'when features are enabled only for team members' do
      let_it_be(:user) { create(:user) }

      before do
        expect(subject).to receive(:member?).and_call_original
      end

      context 'when user is not present' do
        it 'returns false' do
          expect(subject.feature_available?(:feature3)).to eq(false)
        end
      end

      context 'when user can read all resources' do
        it 'returns true' do
          allow(user).to receive(:can_read_all_resources?).and_return(true)

          expect(subject.feature_available?(:feature3, user)).to eq(true)
        end
      end

      context 'when user cannot read all resources' do
        it 'raises NotImplementedError exception' do
          expect(subject).to receive(:resource_member?).and_call_original

          expect { subject.feature_available?(:feature3, user) }.to raise_error(NotImplementedError)
        end
      end
    end

    context 'when feature is enabled for everyone' do
      it 'returns true' do
        expect(subject.feature_available?(:feature2)).to eq(true)
      end
    end
  end
end
