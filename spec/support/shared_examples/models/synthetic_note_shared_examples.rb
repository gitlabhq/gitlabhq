# frozen_string_literal: true

RSpec.shared_examples 'a synthetic note' do |action|
  it_behaves_like 'a system note', exclude_project: true, skip_persistence_check: true do
    let(:action) { action }
  end

  describe '#discussion_id' do
    before do
      allow(event).to receive(:discussion_id).and_return('foobar42')
    end

    it 'returns the expected discussion id' do
      expect(subject.discussion_id(nil)).to eq('foobar42')
    end
  end
end
