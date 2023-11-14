# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/database_dictionary'

RSpec.describe Tooling::Danger::DatabaseDictionary, feature_category: :shared do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }

  subject(:database_dictionary) { fake_danger.new(helper: fake_helper) }

  describe '#database_dictionary_files' do
    let(:database_dictionary_files) do
      [
        'db/docs/ci_pipelines.yml',
        'db/docs/projects.yml'
      ]
    end

    let(:other_files) do
      [
        'app/models/model.rb',
        'app/assets/javascripts/file.js'
      ]
    end

    shared_examples 'an array of Found objects' do |change_type|
      it 'returns an array of Found objects' do
        expect(database_dictionary.database_dictionary_files(change_type: change_type))
          .to contain_exactly(
            an_instance_of(described_class::Found),
            an_instance_of(described_class::Found)
          )

        expect(database_dictionary.database_dictionary_files(change_type: change_type).map(&:path))
          .to eq(database_dictionary_files)
      end
    end

    shared_examples 'an empty array' do |change_type|
      it 'returns an array of Found objects' do
        expect(database_dictionary.database_dictionary_files(change_type: change_type)).to be_empty
      end
    end

    describe 'retrieves added database dictionary files' do
      context 'with added added database dictionary files' do
        let(:added_files) { database_dictionary_files }

        include_examples 'an array of Found objects', :added
      end

      context 'without added added database dictionary files' do
        let(:added_files) { other_files }

        include_examples 'an empty array', :added
      end
    end

    describe 'retrieves modified database dictionary files' do
      context 'with modified modified database dictionary files' do
        let(:modified_files) { database_dictionary_files }

        include_examples 'an array of Found objects', :modified
      end

      context 'without modified modified database dictionary files' do
        let(:modified_files) { other_files }

        include_examples 'an empty array', :modified
      end
    end

    describe 'retrieves deleted database dictionary files' do
      context 'with deleted deleted database dictionary files' do
        let(:deleted_files) { database_dictionary_files }

        include_examples 'an array of Found objects', :deleted
      end

      context 'without deleted deleted database dictionary files' do
        let(:deleted_files) { other_files }

        include_examples 'an empty array', :deleted
      end
    end
  end

  describe described_class::Found do
    let(:database_dictionary_path) { 'db/docs/ci_pipelines.yml' }
    let(:gitlab_schema) { 'gitlab_ci' }

    let(:yaml) do
      {

        'table_name' => 'ci_pipelines',
        'classes' => ['Ci::Pipeline'],
        'feature_categories' => ['continuous_integration'],
        'description' => 'TODO',
        'introduced_by_url' => 'https://gitlab.com/gitlab-org/gitlab/-/commit/c6ae290cea4b88ecaa9cfe0bc9d88e8fd32070c1',
        'milestone' => '9.0',
        'gitlab_schema' => gitlab_schema
      }
    end

    let(:raw_yaml) { YAML.dump(yaml) }

    subject(:found) { described_class.new(database_dictionary_path) }

    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(database_dictionary_path).and_return(raw_yaml)
    end

    described_class::ATTRIBUTES.each do |attribute|
      describe "##{attribute}" do
        it 'returns value from the YAML' do
          expect(found.public_send(attribute)).to eq(yaml[attribute])
        end
      end
    end

    describe '#raw' do
      it 'returns the raw YAML' do
        expect(found.raw).to eq(raw_yaml)
      end
    end

    describe '#ci_schema?' do
      it { expect(found.ci_schema?).to be_truthy }

      context 'with main schema' do
        let(:gitlab_schema) { 'gitlab_main' }

        it { expect(found.ci_schema?).to be_falsey }
      end
    end

    describe '#main_schema?' do
      it { expect(found.main_schema?).to be_falsey }

      context 'with main schema' do
        let(:gitlab_schema) { 'gitlab_main' }

        it { expect(found.main_schema?).to be_truthy }
      end
    end
  end
end
