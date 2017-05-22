require 'spec_helper'

describe Gitlab::Database::Migratable do
  subject do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'ci_pipelines' # PoC mode

      include Gitlab::Database::Migratable

      migrate 234567, 'migration 2'
      migrate 123456, 'migration 1'
    end
  end

  describe '.migrations' do
    it 'exposes migrations method that returns all migrations' do
      expect(subject.migrations).to eq({ 123456 => 'migration 1',
                                         234567 => 'migration 2' })
    end

    it 'returns pending migrations when min version specified' do
      expect(subject.migrations(123456)). to eq({ 234567 => 'migration 2' })
    end
  end

  describe '.latest_schema_version' do
    it 'returns a latest schema version number' do
      expect(subject.latest_schema_version).to eq 234567
    end
  end

  ##
  # TODO, these tests should be changed, PoC mode only.
  #
  context 'when there are not migrated records' do
    let!(:pipeline) { create(:ci_empty_pipeline) }

    before do
      pipeline.update_column(:schema_version, 0)
    end

    it 'exposes a method that checks if migrations are done' do
      expect(subject.migrated?).to eq false
    end

    it 'should raise an error when instantiated' do
      expect { Ci::Pipeline.find(pipeline.id) } # PoC workaround
        .to raise_error Gitlab::Database::Migratable::NotMigratedError
    end
  end
end
