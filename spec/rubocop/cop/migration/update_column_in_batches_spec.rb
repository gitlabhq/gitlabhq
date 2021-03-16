# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../rubocop/cop/migration/update_column_in_batches'

RSpec.describe RuboCop::Cop::Migration::UpdateColumnInBatches do
  let(:cop) { described_class.new }
  let(:tmp_rails_root) { rails_root_join('tmp', 'rails_root') }
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

  let(:spec_filepath) { File.join(tmp_rails_root, 'spec', 'migrations', 'my_super_migration_spec.rb') }

  context 'outside of a migration' do
    it 'does not register any offenses' do
      expect_no_offenses(migration_code)
    end
  end

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
      expect_offense(<<~RUBY, @migration_file)
        def up
          update_column_in_batches(:projects, :name, "foo") do |table, query|
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Migration running `update_column_in_batches` [...]
            query.where(table[:name].eq(nil))
          end
        end
      RUBY
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
      expect_no_offenses(migration_code)
    end
  end

  context 'when in migration' do
    let(:migration_filepath) { File.join(tmp_rails_root, 'db', 'migrate', '20121220064453_my_super_migration.rb') }

    it_behaves_like 'a migration file with no spec file'
    it_behaves_like 'a migration file with a spec file'
  end

  context 'when in a post migration' do
    let(:migration_filepath) { File.join(tmp_rails_root, 'db', 'post_migrate', '20121220064453_my_super_migration.rb') }

    it_behaves_like 'a migration file with no spec file'
    it_behaves_like 'a migration file with a spec file'
  end

  context 'EE migrations' do
    let(:spec_filepath) { File.join(tmp_rails_root, 'ee', 'spec', 'migrations', 'my_super_migration_spec.rb') }

    context 'when in a migration' do
      let(:migration_filepath) { File.join(tmp_rails_root, 'ee', 'db', 'migrate', '20121220064453_my_super_migration.rb') }

      it_behaves_like 'a migration file with no spec file'
      it_behaves_like 'a migration file with a spec file'
    end

    context 'when in a post migration' do
      let(:migration_filepath) { File.join(tmp_rails_root, 'ee', 'db', 'post_migrate', '20121220064453_my_super_migration.rb') }

      it_behaves_like 'a migration file with no spec file'
      it_behaves_like 'a migration file with a spec file'
    end
  end
end
