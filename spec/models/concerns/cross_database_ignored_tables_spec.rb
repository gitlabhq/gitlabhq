# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CrossDatabaseIgnoredTables, feature_category: :cell, query_analyzers: false do
  # We enable only the PreventCrossDatabaseModification query analyzer in these tests
  before do
    stub_const("CiModel", ci_model)
    allow(Gitlab::Database::QueryAnalyzer.instance).to receive(:all_analyzers).and_return(
      [Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification]
    )
  end

  around do |example|
    Gitlab::Database::QueryAnalyzer.instance.within { example.run }
  end

  let(:cross_database_exception) do
    Gitlab::Database::QueryAnalyzers::
        PreventCrossDatabaseModification::CrossDatabaseModificationAcrossUnsupportedTablesError
  end

  let(:ci_model) do
    Class.new(Ci::ApplicationRecord) do
      self.table_name = '_test_gitlab_ci_items'

      belongs_to :main_model_object, class_name: 'MainModel',
        inverse_of: 'ci_model_object', foreign_key: 'main_model_id'
    end
  end

  before_all do
    Ci::ApplicationRecord.connection.execute(
      'CREATE TABLE _test_gitlab_ci_items(
        id BIGSERIAL PRIMARY KEY, main_model_id INTEGER, updated_at timestamp without time zone
      )'
    )
    ApplicationRecord.connection.execute(
      'CREATE TABLE _test_gitlab_main_items(
        id BIGSERIAL PRIMARY KEY, updated_at timestamp without time zone
      )'
    )
  end

  after(:all) do
    ApplicationRecord.connection.execute('DROP TABLE _test_gitlab_main_items')
    Ci::ApplicationRecord.connection.execute('DROP TABLE _test_gitlab_ci_items')
  end

  describe '.cross_database_ignore_tables' do
    context 'when the tables are not ignored' do
      before do
        stub_const("MainModel", create_main_model([], []))
      end

      it 'raises an error when we doing cross-database modification using create' do
        expect { MainModel.create! }.to raise_error(cross_database_exception)
      end

      it 'raises an error when we doing cross-database modification using update' do
        main_model_object = create_main_model_object
        expect { main_model_object.update!(updated_at: Time.zone.now) }.to raise_error(cross_database_exception)
      end

      it 'raises an error when we doing cross-database modification using destroy' do
        main_model_object = create_main_model_object
        expect { main_model_object.destroy! }.to raise_error(cross_database_exception)
      end
    end

    context 'when the tables are ignored on save' do
      before do
        stub_const("MainModel", create_main_model(%w[_test_gitlab_ci_items], %I[save]))
      end

      it 'does not raise an error when creating a new object' do
        expect { MainModel.create! }.not_to raise_error
      end

      it 'does not raise an error when updating an existing object' do
        main_model_object = create_main_model_object
        expect { main_model_object.update!(updated_at: Time.zone.now) }.not_to raise_error
      end

      it 'still raises an error when deleting an object' do # save doesn't include destroy
        main_model_object = create_main_model_object
        expect { main_model_object.destroy! }.to raise_error(cross_database_exception)
      end
    end

    context 'when the tables are ignored on save with if statement' do
      before do
        stub_const(
          "MainModel",
          create_main_model(
            %w[_test_gitlab_ci_items],
            %I[save],
            & proc { condition }
          )
        )

        expect_next_instance_of(MainModel) do |instance|
          allow(instance).to receive(:condition).and_return(condition_value)
        end
      end

      context 'when condition returns true' do
        let(:condition_value) { true }

        it 'does not raise an error on creating a new object' do
          expect { MainModel.create! }.not_to raise_error
        end
      end

      context 'when condition returns false' do
        let(:condition_value) { false }

        it 'raises an error on creating a new object',
          quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/508768' do
          expect { MainModel.create! }.to raise_error(cross_database_exception)
        end
      end
    end

    context 'when the tables are ignored on create' do
      before do
        stub_const("MainModel", create_main_model(%w[_test_gitlab_ci_items], %I[create]))
      end

      it 'does not raise an error when creating a new object' do
        expect { MainModel.create! }.not_to raise_error
      end

      it 'raises an error when updating an existing object' do
        main_model_object = create_main_model_object
        expect { main_model_object.update!(updated_at: Time.zone.now) }.to raise_error(cross_database_exception)
      end

      it 'still raises an error when deleting an object',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/508770' do
        main_model_object = create_main_model_object
        expect { main_model_object.destroy! }.to raise_error(cross_database_exception)
      end
    end

    context 'when the tables are ignored on update' do
      before do
        stub_const("MainModel", create_main_model(%w[_test_gitlab_ci_items], %I[update]))
      end

      it 'raises an error when creating a new object',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/508771' do
        expect { MainModel.create! }.to raise_error(cross_database_exception)
      end

      it 'does not raise an error when updating an existing object' do
        main_model_object = create_main_model_object
        expect { main_model_object.update!(updated_at: Time.zone.now) }.not_to raise_error
      end

      it 'still raises an error when deleting an object',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/508772' do
        main_model_object = create_main_model_object
        expect { main_model_object.destroy! }.to raise_error(cross_database_exception)
      end
    end

    context 'when the tables are ignored on create and destroy' do
      before do
        stub_const("MainModel", create_main_model(%w[_test_gitlab_ci_items], %I[create destroy]))
      end

      it 'does not raise an error when creating a new object' do
        expect { MainModel.create! }.not_to raise_error
      end

      it 'raises an error when updating an existing object' do
        main_model_object = create_main_model_object
        expect { main_model_object.update!(updated_at: Time.zone.now) }.to raise_error(cross_database_exception)
      end

      it 'does not raise an error when deleting an object' do
        main_model_object = create_main_model_object
        expect { main_model_object.destroy! }.not_to raise_error
      end
    end
  end

  def create_main_model(ignored_tables, events, &condition_block)
    klass = Class.new(ApplicationRecord) do
      include CrossDatabaseIgnoredTables

      self.table_name = '_test_gitlab_main_items'

      has_one :ci_model_object, autosave: true, class_name: 'CiModel',
        inverse_of: 'main_model_object', foreign_key: 'main_model_id',
        dependent: :nullify, touch: true
      before_create :prepare_ci_model_object

      def condition
        true
      end

      def prepare_ci_model_object
        build_ci_model_object
      end
    end

    if ignored_tables.any? && events.any?
      klass.class_eval do
        cross_database_ignore_tables ignored_tables, on: events, url: "TODO", if: condition_block
      end
    end

    klass
  end

  # This helper allows creating a test model object without raising a cross database exception
  def create_main_model_object
    Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.temporary_ignore_tables_in_transaction(
      [CiModel.table_name], url: "TODO"
    ) do
      MainModel.create!
    end
  end
end
