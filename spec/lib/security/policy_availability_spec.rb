# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::PolicyAvailability, feature_category: :security_policy_management do
  let_it_be_with_reload(:root_group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: root_group) }
  let_it_be(:project) { create(:project, group: subgroup) }

  describe '.available?' do
    context 'with a policy type gated by the security_orchestration_policies license' do
      using RSpec::Parameterized::TableSyntax

      where(:policy_type) do
        %i[
          security_orchestration_policies
          dependency_firewall
        ]
      end

      with_them do
        it 'is false as this is an EE-only feature' do
          expect(described_class.available?(project, policy_type)).to be(false)
        end
      end
    end

    context 'with an unknown policy type' do
      before do
        stub_licensed_features(security_orchestration_policies: true, dependency_firewall: true)
      end

      it 'is false' do
        expect(described_class.available?(project, :unknown_policy)).to be(false)
      end
    end
  end

  describe '.any_available?' do
    it 'is expected to be false as this is an EE-only feature' do
      expect(described_class.any_available?(project)).to be(false)
    end
  end
end
