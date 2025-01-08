# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PgFullTextSearchable, feature_category: :global_search do
  let(:project) { build(:project, project_namespace: build(:project_namespace)) }

  let(:model_class) do
    Class.new(ActiveRecord::Base) do
      include PgFullTextSearchable

      self.table_name = 'issues'

      belongs_to :project
      belongs_to :namespace
      has_one :search_data, class_name: 'Issues::SearchData'

      before_validation -> { self.work_item_type_id = ::WorkItems::Type.default_issue_type.id }

      def persist_pg_full_text_search_vector(search_vector)
        Issues::SearchData.upsert({ project_id: project_id, issue_id: id, search_vector: search_vector }, unique_by: %i[project_id issue_id])
      end

      def self.name
        'Issue'
      end
    end
  end

  describe '.pg_full_text_searchable' do
    it 'sets pg_full_text_searchable_columns' do
      model_class.pg_full_text_searchable columns: [{ name: 'title', weight: 'A' }]

      expect(model_class.pg_full_text_searchable_columns).to eq({ 'title' => 'A' })
    end

    it 'raises an error when called twice' do
      model_class.pg_full_text_searchable columns: [{ name: 'title', weight: 'A' }]

      expect { model_class.pg_full_text_searchable columns: [{ name: 'title', weight: 'A' }] }.to raise_error('Full text search columns already defined!')
    end
  end

  describe 'after commit hook' do
    let(:model) { model_class.create!(project: project, namespace: project.project_namespace) }

    before do
      model_class.pg_full_text_searchable columns: [{ name: 'title', weight: 'A' }]
    end

    context 'when specified columns are changed' do
      it 'calls update_search_data!' do
        expect(model).to receive(:update_search_data!)

        model.update!(title: 'A new title')
      end
    end

    context 'when specified columns are not changed' do
      it 'does not call update_search_data!' do
        expect(model).not_to receive(:update_search_data!)

        model.update!(description: 'A new description')
      end
    end

    context 'when model is updated twice within a transaction' do
      it 'calls update_search_data!' do
        expect(model).to receive(:update_search_data!)

        model.transaction do
          model.update!(title: 'A new title')
          model.update!(updated_at: Time.current)
        end
      end
    end
  end

  describe '.pg_full_text_search' do
    let(:english) { model_class.create!(project: project, namespace: project.project_namespace, title: 'title', description: 'something description english') }
    let(:with_accent) { model_class.create!(project: project, namespace: project.project_namespace, title: 'Jürgen', description: 'Ærøskøbing') }
    let(:japanese) { model_class.create!(project: project, namespace: project.project_namespace, title: '日本語 title', description: 'another english description') }

    before do
      model_class.pg_full_text_searchable columns: [{ name: 'title', weight: 'A' }, { name: 'description', weight: 'B' }]

      [english, with_accent, japanese].each(&:update_search_data!)
    end

    it 'builds a search query using `search_vector` from the search_data table' do
      sql = model_class.pg_full_text_search('test').to_sql

      expect(sql).to include('"issue_search_data"."search_vector" @@ to_tsquery')
    end

    it 'searches across all fields' do
      expect(model_class.pg_full_text_search('title english')).to contain_exactly(english, japanese)
    end

    context 'with the tsquery_deduplicate_search_terms feature flag' do
      before do
        stub_feature_flags(tsquery_deduplicate_search_terms: true)
      end

      it 'eliminates duplicates' do
        recorder = ActiveRecord::QueryRecorder.new do
          expect(model_class.pg_full_text_search('title title title english english title')).to contain_exactly(english, japanese)
        end
        query = recorder.data.each_value.first[:occurrences][0]

        # Ensure the query doesn't include duplicates for searched words
        expect(query).to include("to_tsquery('english', '''title'':* & ''english'':*')")
      end
    end

    context 'without the tsquery_deduplicate_search_terms feature flag' do
      before do
        stub_feature_flags(tsquery_deduplicate_search_terms: false)
      end

      it 'eliminates duplicates' do
        recorder = ActiveRecord::QueryRecorder.new do
          expect(model_class.pg_full_text_search('title title title english english')).to contain_exactly(english, japanese)
        end
        query = recorder.data.each_value.first[:occurrences][0]

        # The flag is off, so the query should include duplicates for searched words
        expect(query).to include("to_tsquery('english', '''title'':* & ''title'':* & ''title'':* & ''english'':* & ''english'':*')")
      end
    end

    it 'searches specified columns only' do
      matching_object = model_class.create!(project: project, namespace: project.project_namespace, title: 'english', description: 'some description')
      matching_object.update_search_data!

      expect(model_class.pg_full_text_search('english', matched_columns: %w[title])).to contain_exactly(matching_object)
    end

    it 'uses prefix matching' do
      expect(model_class.pg_full_text_search('tit eng')).to contain_exactly(english, japanese)
    end

    it 'searches for exact term with quotes' do
      expect(model_class.pg_full_text_search('"description english"')).to contain_exactly(english)
    end

    it 'ignores accents regardless of user locale' do
      with_accent_in_german = Gitlab::I18n.with_locale(:de) { model_class.create!(project: project, namespace: project.project_namespace, title: 'Jürgen') }

      expect(model_class.pg_full_text_search('jurgen')).to contain_exactly(with_accent, with_accent_in_german)
      expect(model_class.pg_full_text_search('Jürgen')).to contain_exactly(with_accent, with_accent_in_german)
    end

    it 'does not support searching by non-Latin characters' do
      expect(model_class.pg_full_text_search('日本')).to be_empty
    end

    context 'when search term has a URL' do
      let(:with_url) { model_class.create!(project: project, namespace: project.project_namespace, title: 'issue with url', description: 'sample url,https://gitlab.com/gitlab-org/gitlab') }

      it 'allows searching by full URL, ignoring the scheme' do
        with_url.update_search_data!

        expect(model_class.pg_full_text_search('https://gitlab.com/gitlab-org/gitlab')).to contain_exactly(with_url)
        expect(model_class.pg_full_text_search('gopher://gitlab.com/gitlab-org/gitlab')).to contain_exactly(with_url)
      end

      it 'allows searching for URLS with special characters' do
        url_with_params_and_anchor = 'https://gitlab.com/gitlab-org/gitlab?param1=value1&param2=value2#some-anchor'

        with_url.update!(description: url_with_params_and_anchor)
        with_url.update_search_data!

        expect(model_class.pg_full_text_search(url_with_params_and_anchor)).to contain_exactly(with_url)
      end
    end

    context 'when search term is a path with underscores' do
      let(:path) { 'browser_ui/5_package/package_registry/maven/maven_group_level_spec.rb' }
      let(:with_underscore) { model_class.create!(project: project, namespace: project.project_namespace, title: 'issue with path', description: "some #{path} other text") }

      it 'allows searching by the path' do
        with_underscore.update_search_data!

        expect(model_class.pg_full_text_search(path)).to contain_exactly(with_underscore)
      end
    end

    context 'when text has numbers preceded by a dash' do
      let(:with_dash) { model_class.create!(project: project, namespace: project.project_namespace, title: 'issue with dash', description: 'ABC-123') }

      it 'allows searching by numbers only' do
        with_dash.update_search_data!

        expect(model_class.pg_full_text_search('123')).to contain_exactly(with_dash)
      end
    end

    context 'when text has XML tags' do
      let(:with_xml) { model_class.create!(project: project, namespace: project.project_namespace, title: '<rain>go away</rain>', description: 'description') }

      it 'removes XML tag syntax' do
        with_xml.update_search_data!

        expect(model_class.pg_full_text_search('rain')).to contain_exactly(with_xml)
      end
    end
  end

  describe '.pg_full_text_search_in_model' do
    it 'builds a search query using `search_vector` from the model table' do
      sql = model_class.pg_full_text_search_in_model('test').to_sql

      expect(sql).to include('"issues"."search_vector" @@ to_tsquery')
    end
  end

  describe '#update_search_data!' do
    let(:model) { model_class.create!(project: project, namespace: project.project_namespace, title: 'title', description: 'description') }

    before do
      model_class.pg_full_text_searchable columns: [{ name: 'title', weight: 'A' }, { name: 'description', weight: 'B' }]
    end

    it 'sets the correct weights' do
      model.update_search_data!

      expect(model.search_data.search_vector).to match(/'titl':1A/)
      expect(model.search_data.search_vector).to match(/'descript':2B/)
    end

    context 'with accented and non-Latin characters' do
      let(:model) { model_class.create!(project: project, namespace: project.project_namespace, title: '日本語', description: 'Jürgen') }

      it 'transliterates accented characters and removes non-Latin ones' do
        model.update_search_data!

        expect(model.search_data.search_vector).not_to match(/日本語/)
        expect(model.search_data.search_vector).to match(/jurgen/)
      end
    end

    it 'strips words containing @ with length >= 500' do
      model = model_class.create!(project: project, namespace: project.project_namespace, title: 'title', description: 'description ' + ('@user1' * 100))
      model.update_search_data!

      expect(model.search_data.search_vector).to match(/'titl':1A/)
      expect(model.search_data.search_vector).to match(/'descript':2B/)
      expect(model.search_data.search_vector).not_to match(/@user1/)
    end

    context 'with long words' do
      let(:long_word) { ('long/sequence' * 5) + ' ' }
      let(:model) { model_class.create!(project: project, namespace: project.project_namespace, title: 'title', description: 'description ' + (long_word * 51)) }

      it 'strips words with length >= 50 when there are more than 50 instances' do
        model.update_search_data!

        expect(model.search_data.search_vector).to match(/'titl':1A/)
        expect(model.search_data.search_vector).to match(/'descript':2B/)
        expect(model.search_data.search_vector).not_to match(/long/)
        expect(model.search_data.search_vector).not_to match(/sequence/)
      end

      it 'does not strip long words when there are less than 51 instances' do
        model.update!(description: 'description ' + (long_word * 50))
        model.update_search_data!

        expect(model.search_data.search_vector).to match(/'titl':1A/)
        expect(model.search_data.search_vector).to match(/'descript':2B/)
        expect(model.search_data.search_vector).to match(/long/)
        expect(model.search_data.search_vector).to match(/sequence/)
      end
    end

    context 'when upsert times out' do
      it 're-raises the exception' do
        expect(Issues::SearchData).to receive(:upsert).once.and_raise(ActiveRecord::StatementTimeout)

        expect { model.update_search_data! }.to raise_error(ActiveRecord::StatementTimeout)
      end
    end

    context 'with strings that go over tsvector limit', :delete do
      let(:long_string) { Array.new(30_000) { SecureRandom.hex }.join(' ') }
      let(:model) { model_class.create!(project: project, namespace: project.project_namespace, title: 'title', description: long_string) }

      it 'does not raise an exception' do
        expect(Gitlab::AppJsonLogger).to receive(:error).with(
          a_hash_including(class: model_class.name, model_id: model.id)
        )

        expect { model.update_search_data! }.not_to raise_error

        expect(model.search_data).to eq(nil)
      end
    end

    context 'when model class does not implement persist_pg_full_text_search_vector' do
      let(:model_class) do
        Class.new(ActiveRecord::Base) do
          include PgFullTextSearchable

          self.table_name = 'issues'

          belongs_to :project
          belongs_to :namespace
          has_one :search_data, class_name: 'Issues::SearchData'

          before_validation -> { self.work_item_type_id = ::WorkItems::Type.default_issue_type.id }

          def self.name
            'Issue'
          end
        end
      end

      it 'raises an error' do
        expect { model.update_search_data! }.to raise_error(NotImplementedError)
      end
    end
  end
end
