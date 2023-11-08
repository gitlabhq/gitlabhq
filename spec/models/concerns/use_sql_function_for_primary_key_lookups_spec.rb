# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UseSqlFunctionForPrimaryKeyLookups, feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project) }
  let_it_be(:another_project) { create(:project) }

  let(:model) do
    Class.new(ApplicationRecord) do
      self.table_name = :projects

      include UseSqlFunctionForPrimaryKeyLookups
    end
  end

  context 'when the use_sql_functions_for_primary_key_lookups FF is on' do
    before do
      stub_feature_flags(use_sql_functions_for_primary_key_lookups: true)
    end

    it 'loads the correct record' do
      expect(model.find(project.id).id).to eq(project.id)
    end

    it 'uses the fuction-based finder query' do
      query = <<~SQL
      SELECT "projects".* FROM find_projects_by_id(#{project.id})#{' '}
      "projects" WHERE ("projects"."id" IS NOT NULL) LIMIT 1
      SQL
      query_log = ActiveRecord::QueryRecorder.new { model.find(project.id) }.log

      expect(query_log).to match_array(include(query.tr("\n", '')))
    end

    it 'uses query cache', :use_sql_query_cache do
      query = <<~SQL
      SELECT "projects".* FROM find_projects_by_id(#{project.id})#{' '}
      "projects" WHERE ("projects"."id" IS NOT NULL) LIMIT 1
      SQL

      recorder = ActiveRecord::QueryRecorder.new do
        model.find(project.id)
        model.find(project.id)
        model.find(project.id)
      end

      expect(recorder.data.each_value.first[:count]).to eq(1)
      expect(recorder.cached).to include(query.tr("\n", ''))
    end

    context 'when the model has ignored columns' do
      around do |example|
        model.ignored_columns = %i[path]
        example.run
        model.ignored_columns = []
      end

      it 'enumerates the column names' do
        column_list = model.columns.map do |column|
          %("projects"."#{column.name}")
        end.join(', ')

        expect(column_list).not_to include(%("projects"."path"))

        query = <<~SQL
        SELECT #{column_list} FROM find_projects_by_id(#{project.id})#{' '}
        "projects" WHERE ("projects"."id" IS NOT NULL) LIMIT 1
        SQL
        query_log = ActiveRecord::QueryRecorder.new { model.find(project.id) }.log

        expect(query_log).to match_array(include(query.tr("\n", '')))
      end
    end

    context 'when there are scope attributes' do
      let(:scoped_model) do
        Class.new(model) do
          default_scope { where.not(path: nil) } # rubocop: disable Cop/DefaultScope -- Needed for testing a specific case
        end
      end

      it 'loads the correct record' do
        expect(scoped_model.find(project.id).id).to eq(project.id)
      end

      it 'does not use the function-based finder query' do
        query_log = ActiveRecord::QueryRecorder.new { scoped_model.find(project.id) }.log

        expect(query_log).not_to include(match(/find_projects_by_id/))
      end
    end

    context 'when there are multiple arguments' do
      it 'loads the correct records' do
        expect(model.find(project.id, another_project.id).map(&:id)).to match_array([project.id, another_project.id])
      end

      it 'does not use the function-based finder query' do
        query_log = ActiveRecord::QueryRecorder.new { model.find(project.id, another_project.id) }.log

        expect(query_log).not_to include(match(/find_projects_by_id/))
      end
    end

    context 'when there is block given' do
      it 'loads the correct records' do
        expect(model.find(0) { |p| p.path == project.path }.id).to eq(project.id)
      end

      it 'does not use the function-based finder query' do
        query_log = ActiveRecord::QueryRecorder.new { model.find(0) { |p| p.path == project.path } }.log

        expect(query_log).not_to include(match(/find_projects_by_id/))
      end
    end

    context 'when there is no primary key defined' do
      let(:model_without_pk) do
        Class.new(model) do
          def self.primary_key
            nil
          end
        end
      end

      it 'raises ActiveRecord::UnknownPrimaryKey' do
        expect { model_without_pk.find(0) }.to raise_error ActiveRecord::UnknownPrimaryKey
      end
    end

    context 'when id is provided as an array' do
      it 'returns the correct record as an array' do
        expect(model.find([project.id]).map(&:id)).to eq([project.id])
      end

      it 'does use the function-based finder query' do
        query_log = ActiveRecord::QueryRecorder.new { model.find([project.id]) }.log

        expect(query_log).to include(match(/find_projects_by_id/))
      end

      context 'when array has multiple elements' do
        it 'does not use the function-based finder query' do
          query_log = ActiveRecord::QueryRecorder.new { model.find([project.id, another_project.id]) }.log

          expect(query_log).not_to include(match(/find_projects_by_id/))
        end
      end
    end

    context 'when the provided id is null' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect { model.find(nil) }.to raise_error ActiveRecord::RecordNotFound, "Couldn't find  without an ID"
      end
    end

    context 'when the provided id is not a string that can cast to numeric' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect { model.find('foo') }.to raise_error ActiveRecord::RecordNotFound, "Couldn't find  with 'id'=foo"
      end
    end
  end

  context 'when the use_sql_functions_for_primary_key_lookups FF is off' do
    before do
      stub_feature_flags(use_sql_functions_for_primary_key_lookups: false)
    end

    it 'loads the correct record' do
      expect(model.find(project.id).id).to eq(project.id)
    end

    it 'uses the SQL-based finder query' do
      expected_query = %(SELECT "projects".* FROM \"projects\" WHERE "projects"."id" = #{project.id} LIMIT 1)
      query_log = ActiveRecord::QueryRecorder.new { model.find(project.id) }.log

      expect(query_log).to match_array(include(expected_query))
    end
  end
end
