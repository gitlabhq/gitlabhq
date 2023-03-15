# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RepositoryLanguagesService, feature_category: :source_code_management do
  let(:service) { described_class.new(project, project.first_owner) }

  context 'when detected_repository_languages flag is set' do
    let(:project) { create(:project) }

    context 'when a project is without detected programming languages' do
      it 'schedules a worker and returns the empty result' do
        expect(::DetectRepositoryLanguagesWorker).to receive(:perform_async).with(project.id)
        expect(service.execute).to eq([])
      end
    end

    context 'when a project is with detected programming languages' do
      let!(:repository_language) { create(:repository_language, project: project) }

      it 'does not schedule a worker and returns the detected languages' do
        expect(::DetectRepositoryLanguagesWorker).not_to receive(:perform_async).with(project.id)

        languages = service.execute

        expect(languages.size).to eq(1)
        expect(languages.last.attributes.values).to eq(
          [project.id, repository_language.programming_language_id, repository_language.share]
        )
      end

      it 'sets detected_repository_languages flag' do
        expect { service.execute }.to change(project, :detected_repository_languages).from(nil).to(true)
      end
    end
  end

  context 'when detected_repository_languages flag is not set' do
    let!(:repository_language) { create(:repository_language, project: project) }
    let(:project) { create(:project, detected_repository_languages: true) }
    let(:languages) { service.execute }

    it 'returns repository languages' do
      expect(languages.size).to eq(1)
      expect(languages.last.attributes.values).to eq(
        [project.id, repository_language.programming_language_id, repository_language.share]
      )
    end
  end
end
