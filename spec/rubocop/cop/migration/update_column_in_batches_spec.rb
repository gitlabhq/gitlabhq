# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/migration/update_column_in_batches'

RSpec.describe RuboCop::Cop::Migration::UpdateColumnInBatches, feature_category: :database do
  let(:tmp_rails_root) { Pathname.new(rails_root_join('tmp', 'rails_root')) }
  let(:migration_code) do
    <<~RUBY
      def up
        update_column_in_batches(:projects, :name, "foo") do |table, query|
          query.where(table[:name].eq(nil))
        end
      end
    RUBY
  end

  let(:spec_filepath) { 'spec/migrations/my_super_migration_spec.rb' }

  before do
    tmp_rails_root.mkpath
    allow(cop).to receive(:rails_root).and_return(tmp_rails_root)
  end

  after do
    tmp_rails_root.rmtree
  end

  context 'when outside of a migration' do
    it 'does not register any offenses' do
      expect_no_offenses(migration_code)
    end
  end

  shared_examples 'a migration file with no spec file' do
    before do
      touch_file(migration_filepath)
    end

    it 'registers an offense when using update_column_in_batches' do
      expect_offense(<<~RUBY, tmp_rails_root.join(migration_filepath).to_path)
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
    before do
      touch_file(migration_filepath)
      touch_file(spec_filepath)
    end

    it 'does not register any offenses' do
      expect_no_offenses(migration_code)
    end
  end

  context 'when in migration' do
    let(:migration_filepath) { 'db/migrate/20121220064453_my_super_migration.rb' }

    it_behaves_like 'a migration file with no spec file'
    it_behaves_like 'a migration file with a spec file'
  end

  context 'when in a post migration' do
    let(:migration_filepath) { 'db/post_migrate/20121220064453_my_super_migration.rb' }

    it_behaves_like 'a migration file with no spec file'
    it_behaves_like 'a migration file with a spec file'
  end

  context 'for EE migrations' do
    let(:spec_filepath) { 'ee/spec/migrations/my_super_migration_spec.rb' }

    context 'when in a migration' do
      let(:migration_filepath) { 'ee/db/migrate/20121220064453_my_super_migration.rb' }

      it_behaves_like 'a migration file with no spec file'
      it_behaves_like 'a migration file with a spec file'
    end

    context 'when in a post migration' do
      let(:migration_filepath) { 'ee/db/post_migrate/20121220064453_my_super_migration.rb' }

      it_behaves_like 'a migration file with no spec file'
      it_behaves_like 'a migration file with a spec file'
    end
  end

  describe '#external_dependency_checksum' do
    subject { cop.external_dependency_checksum }

    before do
      touch_file('spec/migrations/foo_spec.rb')
      touch_file('spec/migrations/a/nested/bar_spec.rb')
      touch_file('ee/spec/migrations/bar_spec.rb')
    end

    # The computed SHA from sorted list of filenames above
    it { is_expected.to eq('833525c0d9c95d066dbfc8d973153b44a1f8a42694b54de3aaa854cb9f72a6bd') }
  end

  private

  def touch_file(path)
    tmp_rails_root.join(path).tap do |full_path|
      full_path.dirname.mkpath
      full_path.write('')
    end
  end
end
