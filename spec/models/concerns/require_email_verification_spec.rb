# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequireEmailVerification, feature_category: :insider_threat do
  let_it_be(:model) do
    Class.new(ApplicationRecord) do
      self.table_name = 'users'

      devise :lockable

      include RequireEmailVerification
    end
  end

  using RSpec::Parameterized::TableSyntax

  where(feature_flag_enabled: [true, false],
    two_factor_enabled: [true, false],
    oauth_user: [true, false],
    skipped: [true, false])

  with_them do
    let(:instance) { model.new(id: 1) }
    let(:another_instance) { model.new(id: 2) }
    let(:overridden) { feature_flag_enabled && !two_factor_enabled && !oauth_user && !skipped }

    before do
      stub_feature_flags(require_email_verification: feature_flag_enabled ? instance : another_instance)
      allow(instance).to receive(:two_factor_enabled?).and_return(two_factor_enabled)
      allow(instance).to receive(:identities).and_return(oauth_user ? [:google] : [])
      stub_feature_flags(skip_require_email_verification: skipped ? instance : another_instance)
    end

    describe '#lock_access!' do
      subject { instance.lock_access! }

      before do
        allow(instance).to receive(:save)
      end

      it 'sends Devise unlock instructions unless overridden and always sets locked_at' do
        expect(instance).to receive(:send_unlock_instructions).exactly(overridden ? 0 : 1).times

        expect { subject }.to change { instance.locked_at }.from(nil)
      end
    end

    describe '#attempts_exceeded?' do
      subject { instance.send(:attempts_exceeded?) }

      context 'when failed_attempts is LT overridden amount' do
        before do
          instance.failed_attempts = 2
        end

        it { is_expected.to eq(false) }
      end

      context 'when failed_attempts is GTE overridden amount but LT Devise default amount' do
        before do
          instance.failed_attempts = 6
        end

        it { is_expected.to eq(overridden) }
      end

      context 'when failed_attempts is GTE Devise default amount' do
        before do
          instance.failed_attempts = instance.class.maximum_attempts
        end

        it { is_expected.to eq(true) }
      end
    end

    describe '#lock_expired?' do
      subject { instance.send(:lock_expired?) }

      context 'when locked shorter ago than Devise default time' do
        before do
          instance.locked_at = 9.minutes.ago
        end

        it { is_expected.to eq(false) }
      end

      context 'when locked longer ago than Devise default time but shorter ago than overriden time' do
        before do
          instance.locked_at = (instance.class.unlock_in + 1.minute).ago
        end

        it { is_expected.to eq(!overridden) }
      end

      context 'when locked longer ago than overriden time' do
        before do
          instance.locked_at = (24.hours + 1.minute).ago
        end

        it { is_expected.to eq(true) }
      end
    end
  end
end
