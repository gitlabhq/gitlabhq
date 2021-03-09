# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::ProjectExportPresenter do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  subject { described_class.new(project, current_user: user) }

  describe '#description' do
    context "override_description not provided" do
      it "keeps original description" do
        expect(subject.description).to eq(project.description)
      end
    end

    context "override_description provided" do
      let(:description) { "overridden description" }

      subject { described_class.new(project, current_user: user, override_description: description) }

      it "overrides description" do
        expect(subject.description).to eq(description)
      end
    end
  end

  describe '#as_json' do
    context "override_description not provided" do
      it "keeps original description" do
        expect(subject.as_json["description"]).to eq(project.description)
      end
    end

    context "override_description provided" do
      let(:description) { "overridden description" }

      subject { described_class.new(project, current_user: user, override_description: description) }

      it "overrides description" do
        expect(subject.as_json["description"]).to eq(description)
      end
    end
  end

  describe '#protected_branches' do
    it 'returns the project exported protected branches' do
      expect(project).to receive(:exported_protected_branches)

      subject.protected_branches
    end
  end

  describe '#project_members' do
    let(:user2) { create(:user, email: 'group@member.com') }
    let(:member_emails) do
      subject.project_members.map do |pm|
        pm.user.email
      end
    end

    before do
      group.add_developer(user2)
    end

    it 'does not export group members if it has no permission' do
      group.add_developer(user)

      expect(member_emails).not_to include('group@member.com')
    end

    it 'does not export group members as maintainer' do
      group.add_maintainer(user)

      expect(member_emails).not_to include('group@member.com')
    end

    it 'exports group members as group owner' do
      group.add_owner(user)

      expect(member_emails).to include('group@member.com')
    end

    context 'as admin' do
      let(:user) { create(:admin) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'exports group members as admin' do
          expect(member_emails).to include('group@member.com')
        end

        it 'exports group members as project members' do
          member_types = subject.project_members.map { |pm| pm.source_type }

          expect(member_types).to all(eq('Project'))
        end
      end

      context 'when admin mode is disabled' do
        it 'does not export group members' do
          expect(member_emails).not_to include('group@member.com')
        end
      end
    end
  end
end
