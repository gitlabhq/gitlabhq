# frozen_string_literal: true

RSpec.shared_examples 'protected tag access' do
  include_examples 'protected ref access', :protected_tag

  let_it_be(:protected_tag) { create(:protected_tag) }

  it { is_expected.to belong_to(:protected_tag) }

  describe '#project' do
    it 'delegates project to protected_tag association' do
      allow(protected_tag).to receive(:project)

      described_class.new(protected_tag: protected_tag).project

      expect(protected_tag).to have_received(:project)
    end

    it 'does not error when protected_tag is nil' do
      expect(described_class.new.project).to be_nil
    end
  end
end
