# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DetectRepositoryLanguagesService, :clean_gitlab_redis_shared_state, feature_category: :groups_and_projects do
  let_it_be(:project, reload: true) { create(:project, :repository) }

  subject { described_class.new(project) }

  describe '#execute' do
    context 'without previous detection' do
      it 'inserts new programming languages in the database' do
        subject.execute

        expect(ProgrammingLanguage.exists?(name: 'Ruby')).to be(true)
        expect(ProgrammingLanguage.count).to be(4)
      end

      it 'inserts the repository langauges' do
        names = subject.execute.map(&:name)

        expect(names).to eq(%w[Ruby JavaScript HTML CoffeeScript])
      end

      it 'updates detected_repository_languages flag' do
        expect { subject.execute }.to change { project.detected_repository_languages }.to(true)
      end

      it 'persists language_id on newly created programming languages' do
        subject.execute

        ruby_lang = ProgrammingLanguage.find_by(name: 'Ruby')
        expect(ruby_lang.language_id).to be_present
      end
    end

    context 'with a previous detection' do
      before do
        subject.execute

        allow(project.repository).to receive(:languages).and_return(
          [{ value: 99.63, label: "Ruby", color: "#701516", highlight: "#701516", language_id: 326 },
            { value: 0.3, label: "D", color: "#701516", highlight: "#701516", language_id: 85 }]
        )
      end

      it 'updates the repository languages' do
        repository_languages = subject.execute.map(&:name)

        expect(repository_languages).to eq(%w[Ruby D])
      end

      it "doesn't touch detected_repository_languages flag" do
        expect(project).not_to receive(:update_column).with(:detected_repository_languages, true)

        subject.execute
      end
    end

    context 'when Gitaly returns nil for language_id' do
      before do
        allow(project.repository).to receive(:languages).and_return(
          [{ value: 99.0, label: "NewLang", color: "#abcdef", highlight: "#abcdef", language_id: nil }]
        )
      end

      it 'creates the programming language without language_id' do
        subject.execute

        lang = ProgrammingLanguage.find_by(name: 'NewLang')
        expect(lang).to be_present
        expect(lang.language_id).to be_nil
      end
    end

    context 'when no repository exists' do
      let_it_be(:project) { create(:project) }

      it 'has no languages' do
        expect(subject.execute).to be_empty
        expect(project.repository_languages).to be_empty
      end
    end
  end
end
