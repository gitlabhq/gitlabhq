require 'spec_helper'

describe ChatNotificationService do
  describe 'Associations' do
    before do
      allow(subject).to receive(:activated?).and_return(true)
    end

    it { is_expected.to validate_presence_of :webhook }
  end

  describe '#can_test?' do
    context 'with empty repository' do
      it 'returns true' do
        subject.project = create(:project, :empty_repo)

        expect(subject.can_test?).to be true
      end
    end

    context 'with repository' do
      it 'returns true' do
        subject.project = create(:project, :repository)

        expect(subject.can_test?).to be true
      end
    end
  end
end
