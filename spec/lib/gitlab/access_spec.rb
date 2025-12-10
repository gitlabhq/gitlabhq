# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Access, feature_category: :permissions do
  include RolesHelpers

  let_it_be(:member) { create(:group_member, :developer) }

  describe '#role_description' do
    it 'returns the correct description of the access role' do
      role = described_class.option_descriptions[described_class::DEVELOPER]

      expect(member.role_description).to eq(role)
    end
  end

  describe '.level_encompasses?' do
    def level_encompasses?(current_level, level_to_assign)
      described_class.level_encompasses?(
        current_access_level: access_level_value(current_level),
        level_to_assign: access_level_value(level_to_assign)
      )
    end

    RolesHelpers.assignable_roles.each do |current_level, expected|
      context "with #{current_level}" do
        not_expected = Gitlab::Access.sym_options_with_owner.keys - expected

        expected.each do |level_to_assign|
          it "encompasses #{level_to_assign}" do
            result = level_encompasses?(current_level, level_to_assign)
            expect(result).to be(true)
          end
        end

        not_expected.each do |level_to_assign|
          it "does not encompass #{level_to_assign}" do
            result = level_encompasses?(current_level, level_to_assign)
            expect(result).to be(false)
          end
        end
      end
    end

    it 'returns false when current_access_level is nil' do
      result = described_class.level_encompasses?(
        current_access_level: nil,
        level_to_assign: Gitlab::Access::MAINTAINER
      )
      expect(result).to be(false)
    end
  end

  describe '.options' do
    it 'returns correct role options in correct order' do
      expect(described_class.options.keys).to eq(%w[Guest Planner Reporter Developer Maintainer])
    end

    context 'when security manager role is enabled' do
      before do
        allow(Gitlab::Security::SecurityManagerConfig).to receive(:enabled?).and_return(true)
      end

      it 'returns roles in correct order between Reporter and Developer' do
        expect(described_class.options.keys).to eq(["Guest", "Planner", "Reporter", "Security Manager", "Developer",
          "Maintainer"])
      end

      it 'includes Security Manager with correct access level' do
        expect(described_class.options['Security Manager']).to eq(25)
      end
    end
  end

  describe '.option_descriptions' do
    it 'does not include Security Manager description' do
      expect(described_class.option_descriptions).not_to have_key(25)
    end

    context 'when security manager role is enabled' do
      before do
        allow(Gitlab::Security::SecurityManagerConfig).to receive(:enabled?).and_return(true)
      end

      it 'includes Security Manager description' do
        expect(described_class.option_descriptions).to have_key(25)
        expect(described_class.option_descriptions[25]).to include('Security Manager')
      end
    end
  end

  describe '.sym_options' do
    it 'returns roles in correct order' do
      expect(described_class.sym_options.keys).to eq([:guest, :planner, :reporter, :developer, :maintainer])
    end

    context 'when security manager role is enabled' do
      before do
        allow(Gitlab::Security::SecurityManagerConfig).to receive(:enabled?).and_return(true)
      end

      it 'returns roles in correct order between reporter and developer' do
        expect(described_class.sym_options.keys).to eq(
          [:guest, :planner, :reporter, :security_manager, :developer, :maintainer]
        )
      end

      it 'includes security_manager with correct access level' do
        expect(described_class.sym_options[:security_manager]).to eq(25)
      end
    end
  end
end
