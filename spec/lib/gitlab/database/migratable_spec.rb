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

  it 'exposes migrations method that returns all migrations' do
    expect(subject.migrations).to eq({ 234567 => 'migration 2',
                                       123456 => 'migration 1' })
  end

  it 'exposes a method that returns a latest schema version number' do
    expect(subject.latest_schema_version).to eq 234567
  end

  ##
  # TODO, these tests should be changed, PoC mode only.
  #
  context 'when there are not migrated records' do
    before { create(:ci_empty_pipeline) }

    it 'exposes a method that checks if migrations are done' do
      expect(subject.migrated?(Ci::Pipeline.all)).to eq false
    end

    it 'should raise an error when instantiated' do
      expect { subject.new }
        .to raise_error Gitlab::Database::Migratable::NotMigratedError
    end
  end
end
