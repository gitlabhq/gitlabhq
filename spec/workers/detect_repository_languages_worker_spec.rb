# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DetectRepositoryLanguagesWorker, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }

  subject { described_class.new }

  describe '#perform' do
    it 'calls de DetectRepositoryLanguages service' do
      service = double
      allow(::Projects::DetectRepositoryLanguagesService).to receive(:new).and_return(service)
      expect(service).to receive(:execute)

      subject.perform(project.id)
    end

    context 'when invalid ids are used' do
      it 'does not raise when the project could not be found' do
        expect do
          subject.perform(-1)
        end.not_to raise_error
      end
    end
  end
end
