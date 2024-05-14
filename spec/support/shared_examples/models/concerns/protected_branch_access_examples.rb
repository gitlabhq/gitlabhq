# frozen_string_literal: true

RSpec.shared_examples 'protected branch access' do
  include_examples 'protected ref access', :protected_branch

  it { is_expected.to belong_to(:protected_branch) }

  describe '#project' do
    it 'delegates project to protected_branch association' do
      allow(protected_ref).to receive(:project)

      described_class.new(protected_branch: protected_ref).project

      expect(protected_ref).to have_received(:project)
    end
  end

  describe '#protected_branch_group' do
    it 'looks for the group attached to protected_branch' do
      allow(protected_ref).to receive(:group)

      described_class.new(protected_branch: protected_ref).protected_branch_group

      expect(protected_ref).to have_received(:group)
    end
  end

  context 'when current_project is nil' do
    context "and protected_branch_group isn't nil" do
      let_it_be(:group) { create(:group) }
      let_it_be(:current_user) { create(:user) }
      let_it_be(:protected_ref) { create(:protected_branch, project: nil, group: group) }
      let_it_be(:access_level) { ::Gitlab::Access::DEVELOPER }

      using RSpec::Parameterized::TableSyntax

      where(:assign_access_level, :expected_check_access) do
        :guest      | false
        :reporter   | false
        :developer  | true
        :maintainer | true
        :owner      | true
      end

      with_them do
        subject do
          group.add_member(current_user, assign_access_level)

          described_class.new(protected_branch: protected_ref, access_level: access_level).check_access(current_user,
            nil)
        end

        it { is_expected.to eq(expected_check_access) }
      end
    end
  end
end
