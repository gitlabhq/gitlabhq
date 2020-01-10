# frozen_string_literal: true

require 'spec_helper'

describe Projects::DetectRepositoryLanguagesService, :clean_gitlab_redis_shared_state do
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
        expect { subject.execute }.to change(project, :detected_repository_languages).to(true)
      end
    end

    context 'with a previous detection' do
      before do
        subject.execute

        allow(project.repository).to receive(:languages).and_return(
          [{ value: 99.63, label: "Ruby", color: "#701516", highlight: "#701516" },
           { value: 0.3, label: "D", color: "#701516", highlight: "#701516" }]
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

    context 'when no repository exists' do
      let_it_be(:project) { create(:project) }

      it 'has no languages' do
        expect(subject.execute).to be_empty
        expect(project.repository_languages).to be_empty
      end
    end
  end
end
