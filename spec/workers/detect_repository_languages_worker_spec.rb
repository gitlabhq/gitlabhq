require 'spec_helper'

describe DetectRepositoryLanguagesWorker do
  set(:project) { create(:project) }
  let(:user) { project.owner }

  subject { described_class.new }

  describe '#perform' do
    it 'calls de DetectRepositoryLanguages service' do
      service = double
      allow(::Projects::DetectRepositoryLanguagesService).to receive(:new).and_return(service)
      expect(service).to receive(:execute)

      subject.perform(project.id, user.id)
    end

    context 'when invalid ids are used' do
      it 'does not raise when the project could not be found' do
        expect do
          subject.perform(-1, user.id)
        end.not_to raise_error
      end

      it 'does not raise when the user could not be found' do
        expect do
          subject.perform(project.id, -1)
        end.not_to raise_error
      end
    end
  end
end
