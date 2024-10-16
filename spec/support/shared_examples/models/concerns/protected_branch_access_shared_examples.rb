# frozen_string_literal: true

RSpec.shared_examples 'protected branch access' do
  it_behaves_like 'protected ref access'

  it { is_expected.to belong_to(:protected_branch) }

  describe '#project' do
    include_context 'for protected ref access'

    it 'delegates project to protected_branch association' do
      allow(protected_ref).to receive(:project)

      described_class.new(protected_branch: protected_ref).project

      expect(protected_ref).to have_received(:project)
    end

    it 'does not error when protected_branch is nil' do
      expect(described_class.new.project).to be_nil
    end
  end

  describe '#protected_branch_group' do
    include_context 'for protected ref access'

    it 'looks for the group attached to protected_branch' do
      allow(protected_ref).to receive(:group)

      described_class.new(protected_branch: protected_ref).protected_branch_group

      expect(protected_ref).to have_received(:group)
    end
  end
end
