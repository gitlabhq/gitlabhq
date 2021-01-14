# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberSerializer do
  include MembersPresentation

  let_it_be(:current_user) { create(:user) }

  subject { described_class.new.represent(members, { current_user: current_user, group: group }) }

  shared_examples 'members.json' do
    it 'matches json schema' do
      expect(subject.to_json).to match_schema('members')
    end
  end

  context 'group member' do
    let(:group) { create(:group) }
    let(:members) { present_members(create_list(:group_member, 1, group: group)) }

    it_behaves_like 'members.json'
  end

  context 'project member' do
    let(:project) { create(:project) }
    let(:group) { project.group }
    let(:members) { present_members(create_list(:project_member, 1, project: project)) }

    it_behaves_like 'members.json'
  end
end
