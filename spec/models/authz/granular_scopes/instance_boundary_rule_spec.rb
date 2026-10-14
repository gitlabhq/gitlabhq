# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::GranularScopes::InstanceBoundaryRule, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let(:rule) { described_class.new }

  describe '#allowed_access?' do
    where(:access, :allowed) do
      :user                 | true
      :instance             | true
      :all_memberships      | true
      :selected_memberships | true
      :personal_projects    | false
      'instance'            | true
      :unknown              | false
      nil                   | false
    end

    with_them do
      it { expect(rule.allowed_access?(access)).to be(allowed) }
    end
  end

  describe '#allowed_resource?' do
    it 'allows any group or project' do
      expect(rule.allowed_resource?(build_stubbed(:group))).to be(true)
      expect(rule.allowed_resource?(build_stubbed(:project))).to be(true)
    end
  end

  describe '#personal_projects_namespace' do
    it 'raises because an instance application has no personal namespace' do
      expect { rule.personal_projects_namespace }
        .to raise_error(Authz::GranularScopes::AccessNotAllowedError)
    end
  end
end
