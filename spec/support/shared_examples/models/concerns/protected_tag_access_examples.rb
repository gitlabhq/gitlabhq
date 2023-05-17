# frozen_string_literal: true

RSpec.shared_examples 'protected tag access' do
  include_examples 'protected ref access', :protected_tag

  let_it_be(:protected_tag) { create(:protected_tag) }

  it { is_expected.to belong_to(:protected_tag) }

  describe '#project' do
    before do
      allow(protected_tag).to receive(:project)
    end

    it 'delegates project to protected_tag association' do
      described_class.new(protected_tag: protected_tag).project

      expect(protected_tag).to have_received(:project)
    end
  end
end
