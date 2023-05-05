# frozen_string_literal: true

RSpec.shared_examples 'protected branch access' do
  include_examples 'protected ref access', :protected_branch

  it { is_expected.to belong_to(:protected_branch) }

  describe '#project' do
    before do
      allow(protected_ref).to receive(:project)
    end

    it 'delegates project to protected_branch association' do
      described_class.new(protected_branch: protected_ref).project

      expect(protected_ref).to have_received(:project)
    end
  end
end
