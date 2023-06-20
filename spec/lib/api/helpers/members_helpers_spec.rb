# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::MembersHelpers, feature_category: :groups_and_projects do
  let(:helper) do
    Class.new.include(described_class).new
  end

  describe '#source_members' do
    subject(:source_members) { helper.source_members(source) }

    shared_examples_for 'returns all direct members' do
      specify do
        expect(source_members).to match_array(direct_members)
      end
    end

    context 'for a group' do
      let_it_be(:source) { create(:group) }
      let_it_be(:direct_members) { create_list(:group_member, 2, group: source) }

      it_behaves_like 'returns all direct members'
      it_behaves_like 'query with source filters'
    end

    context 'for a project' do
      let_it_be(:source) { create(:project, group: create(:group)) }
      let_it_be(:direct_members) { create_list(:project_member, 2, project: source) }

      it_behaves_like 'returns all direct members'
      it_behaves_like 'query without source filters'
    end
  end
end
