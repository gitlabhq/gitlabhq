require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/update_column_in_batches'

describe RuboCop::Cop::Migration::UpdateColumnInBatches do
  let(:cop) { described_class.new }
  let(:tmp_rails_root) { Rails.root.join('tmp', 'rails_root') }
  let(:migration_code) do
    <<-END
    def up
      update_column_in_batches(:projects, :name, "foo") do |table, query|
        query.where(table[:name].eq(nil))
      end
    end
    END
  end

  before do
    allow(cop).to receive(:rails_root).and_return(tmp_rails_root)
  end
  after do
    FileUtils.rm_rf(tmp_rails_root)
  end

  context 'outside of a migration' do
    it 'does not register any offenses' do
      inspect_source(migration_code)

      expect(cop.offenses).to be_empty
    end
  end

  let(:spec_filepath) { tmp_rails_root.join('spec', 'migrations', 'my_super_migration_spec.rb') }

  shared_context 'with a migration file' do
    before do
      FileUtils.mkdir_p(File.dirname(migration_filepath))
      @migration_file = File.new(migration_filepath, 'w+')
    end
    after do
      @migration_file.close
    end
  end

  shared_examples 'a migration file with no spec file' do
    include_context 'with a migration file'

    let(:relative_spec_filepath) { Pathname.new(spec_filepath).relative_path_from(tmp_rails_root) }

    it 'registers an offense when using update_column_in_batches' do
      inspect_source(migration_code, @migration_file)

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([2])
        expect(cop.offenses.first.message)
          .to include("`#{relative_spec_filepath}`")
      end
    end
  end

  shared_examples 'a migration file with a spec file' do
    include_context 'with a migration file'

    before do
      FileUtils.mkdir_p(File.dirname(spec_filepath))
      @spec_file = File.new(spec_filepath, 'w+')
    end
    after do
      @spec_file.close
    end

    it 'does not register any offenses' do
      inspect_source(migration_code, @migration_file)

      expect(cop.offenses).to be_empty
    end
  end

  context 'in a migration' do
    let(:migration_filepath) { tmp_rails_root.join('db', 'migrate', '20121220064453_my_super_migration.rb') }

    it_behaves_like 'a migration file with no spec file'
    it_behaves_like 'a migration file with a spec file'
  end

  context 'in a post migration' do
    let(:migration_filepath) { tmp_rails_root.join('db', 'post_migrate', '20121220064453_my_super_migration.rb') }

    it_behaves_like 'a migration file with no spec file'
    it_behaves_like 'a migration file with a spec file'
  end
end
