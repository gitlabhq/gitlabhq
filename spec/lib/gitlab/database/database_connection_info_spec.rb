# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::DatabaseConnectionInfo, feature_category: :cell do
  let(:default_attributes) do
    {
      name: 'main',
      gitlab_schemas: ['gitlab_main'],
      klass: 'ActiveRecord::Base'
    }
  end

  let(:attributes) { default_attributes }

  subject { described_class.new(attributes) }

  describe '.new' do
    let(:attributes) { default_attributes.merge(fallback_database: 'fallback') }

    it 'does convert attributes into symbols and objects' do
      expect(subject.name).to be_a(Symbol)
      expect(subject.gitlab_schemas).to all(be_a(Symbol))
      expect(subject.klass).to be(ActiveRecord::Base)
      expect(subject.fallback_database).to be_a(Symbol)
      expect(subject.db_dir).to be_a(Pathname)
    end

    it 'does raise error when using invalid argument' do
      expect { described_class.new(invalid: 'aa') }.to raise_error ArgumentError, /unknown keywords: invalid/
    end
  end

  describe '.load_file' do
    it 'does load YAML file and has file_path specified' do
      file_path = Rails.root.join('db/database_connections/main.yaml')
      db_info = described_class.load_file(file_path)

      expect(db_info).not_to be_nil
      expect(db_info.file_path).to eq(file_path)
    end
  end

  describe '#connection_class' do
    context 'when klass is "ActiveRecord::Base"' do
      let(:attributes) { default_attributes.merge(klass: 'ActiveRecord::Base') }

      it 'does always return "ActiveRecord::Base"' do
        expect(subject.connection_class).to eq(ActiveRecord::Base)
      end
    end

    context 'when klass is "Ci::ApplicationRecord"' do
      let(:attributes) { default_attributes.merge(klass: 'Ci::ApplicationRecord') }

      it 'does return "Ci::ApplicationRecord" when it is connection_class' do
        expect(Ci::ApplicationRecord).to receive(:connection_class).and_return(true)

        expect(subject.connection_class).to eq(Ci::ApplicationRecord)
      end

      it 'does return nil when it is not connection_class' do
        expect(Ci::ApplicationRecord).to receive(:connection_class).and_return(false)

        expect(subject.connection_class).to eq(nil)
      end
    end
  end

  describe '#order' do
    using RSpec::Parameterized::TableSyntax

    let(:configs_for) { %w[main ci geo] }

    before do
      hash_configs = configs_for.map do |x|
        instance_double(ActiveRecord::DatabaseConfigurations::HashConfig, name: x)
      end
      allow(::ActiveRecord::Base).to receive(:configurations).and_return(
        instance_double(ActiveRecord::DatabaseConfigurations, configs_for: hash_configs)
      )
    end

    where(:name, :order) do
      :main | 0
      :ci | 1
      :undefined | 1000
    end

    with_them do
      let(:attributes) { default_attributes.merge(name: name) }

      it { expect(subject.order).to eq(order) }
    end
  end

  describe '#connection_class_or_fallback' do
    let(:all_databases) do
      {
        main: described_class.new(
          name: 'main', gitlab_schemas: [], klass: 'ActiveRecord::Base'),
        ci: described_class.new(
          name: 'ci', gitlab_schemas: [], klass: 'Ci::ApplicationRecord', fallback_database: 'main')
      }
    end

    context 'for "main"' do
      it 'does return ActiveRecord::Base' do
        expect(all_databases[:main].connection_class_or_fallback(all_databases))
          .to eq(ActiveRecord::Base)
      end
    end

    context 'for "ci"' do
      it 'does return "Ci::ApplicationRecord" when it is connection_class' do
        expect(Ci::ApplicationRecord).to receive(:connection_class).and_return(true)

        expect(all_databases[:ci].connection_class_or_fallback(all_databases))
          .to eq(Ci::ApplicationRecord)
      end

      it 'does return "ActiveRecord::Base" (fallback to "main") when it is not connection_class' do
        expect(Ci::ApplicationRecord).to receive(:connection_class).and_return(false)

        expect(all_databases[:ci].connection_class_or_fallback(all_databases))
          .to eq(ActiveRecord::Base)
      end
    end
  end

  describe '#has_gitlab_shared?' do
    using RSpec::Parameterized::TableSyntax

    where(:gitlab_schemas, :result) do
      %w[gitlab_main] | false
      %w[gitlab_main gitlab_shared] | true
    end

    with_them do
      let(:attributes) { default_attributes.merge(gitlab_schemas: gitlab_schemas) }

      it { expect(subject.has_gitlab_shared?).to eq(result) }
    end
  end

  describe 'db_docs_dir' do
    let(:attributes) { default_attributes.merge(db_dir: db_dir) }

    context 'when db_dir is specified' do
      let(:db_dir) { 'ee/my/db' }

      it { expect(subject.db_docs_dir).to eq(Rails.root.join(db_dir, 'docs')) }
    end

    context 'when db_dir is not specified fallbacks to "db/docs"' do
      let(:db_dir) { nil }

      it { expect(subject.db_docs_dir).to eq(Rails.root.join('db/docs')) }
    end
  end
end
