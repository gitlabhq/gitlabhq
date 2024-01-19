# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::GroupDetail, feature_category: :groups_and_projects do
  describe '#as_json' do
    subject { described_class.new(group, options).as_json }

    let_it_be(:root_group) { create(:group) }
    let_it_be(:subgroup) { create(:group, :nested) }

    let(:options) { {} }

    describe '#prevent_sharing_groups_outside_hierarchy' do
      context 'for a root group' do
        let(:group) { root_group }

        it { is_expected.to include(:prevent_sharing_groups_outside_hierarchy) }
      end

      context 'for a subgroup' do
        let(:group) { subgroup }

        it { is_expected.not_to include(:prevent_sharing_groups_outside_hierarchy) }
      end
    end

    describe '#enabled_git_access_protocol' do
      using RSpec::Parameterized::TableSyntax

      where(:group, :can_admin_group, :includes_field) do
        ref(:root_group) | false | false
        ref(:root_group) | true | true
        ref(:subgroup) | false | false
        ref(:subgroup) | true | false
      end

      with_them do
        let(:options) { { user_can_admin_group: can_admin_group } }

        it 'verifies presence of the field' do
          if includes_field
            is_expected.to include(:enabled_git_access_protocol)
          else
            is_expected.not_to include(:enabled_git_access_protocol)
          end
        end
      end
    end
  end
end
