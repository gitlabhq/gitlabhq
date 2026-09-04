# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/ensure_factory_for_table'

RSpec.describe RuboCop::Cop::Migration::EnsureFactoryForTable, feature_category: :database do
  context 'with faked factories' do
    let(:ee) { true }

    let(:dictionary_classes) { [] }
    let(:factory_names) { Set.new }
    let(:factory_classes) { Set.new }
    let(:factory_inferred_classes) { Set.new }

    before do
      allow(described_class).to receive_messages(
        factories: factories,
        dictionary_classes: dictionary_classes,
        factory_names: factory_names,
        factory_classes: factory_classes,
        factory_inferred_classes: factory_inferred_classes
      )
      allow(cop).to receive(:ee?).and_return(ee)
    end

    context 'without matching factories' do
      let(:factories) { [] }

      it 'registers an offense when a table does not have a corresponding factory' do
        expect_offense(<<~RUBY)
        create_table :users do |t|
                     ^^^^^^ No factory found for the table `users`.
          t.string :name
          t.timestamps
        end

        create_table "users" do |t|
                     ^^^^^^^ No factory found for the table `users`.
          t.string :name
          t.timestamps
        end
        RUBY
      end

      it 'does not register an offense for non-string and non-symbol table name' do
        expect_no_offenses(<<~RUBY)
        TABLE = :users

        create_table TABLE do |t|
          t.string :name
          t.timestamps
        end
        RUBY
      end

      context 'when non-EE' do
        let(:ee) { false }

        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
          create_table :users do |t|
            t.string :name
            t.timestamps
          end
          RUBY
        end

        context 'with rubocop:disable comment' do
          let(:source) do
            <<~RUBY
              create_table :users do |t| # rubocop:disable Migration/EnsureFactoryForTable  -- Some reason
                t.string :name
                t.timestamps
              end
            RUBY
          end

          it 'adds a disabled offense for Migration/EnsureFactoryForTable to avoid Lint/RedundantCopDisableDirective' do
            # rubocop:disable InternalAffairs/DeprecateCopHelper -- Can't use methods from RuboCop::RSpec::ExpectOffense
            # here as they remove the disabled offenses.
            processed_source = parse_source(source)
            # rubocop:enable InternalAffairs/DeprecateCopHelper

            team = RuboCop::Cop::Team.new([cop], configuration, raise_error: true)

            offenses = team.investigate(processed_source).offenses
            offense = offenses.first
            expect(offenses.size).to eq(1)
            expect(offense.cop_name).to eq(cop.name)
            expect(offense.status).to eq(:disabled)
          end
        end
      end
    end

    context 'with matching factories' do
      context 'with regular table' do
        let(:factories) { ['users'] }

        it 'does not register an offense when a table has a corresponding factory' do
          expect_no_offenses(<<~RUBY)
          create_table :users do |t|
            t.string :name
            t.timestamps
          end
          RUBY
        end
      end

      context 'with partitioned table' do
        let(:factories) { ['users'] }

        it 'does not register an offense when a table has a corresponding factory' do
          expect_no_offenses(<<~RUBY)
          create_table :p_users do |t|
            t.string :name
            t.timestamps
          end
          RUBY
        end
      end
    end

    context 'with dictionary-based factory matching' do
      let(:factories) { [] }

      let(:source) do
        <<~RUBY
        create_table :packages_debian_file_metadata do |t|
          t.string :name
          t.timestamps
        end
        RUBY
      end

      context 'when a factory declares the class listed in the dictionary' do
        let(:dictionary_classes) { ['Packages::Debian::FileMetadatum'] }
        let(:factory_classes) { Set.new(['Packages::Debian::FileMetadatum']) }

        it 'does not register an offense' do
          expect_no_offenses(source)
        end
      end

      context 'when FactoryBot would infer the dictionary class from a factory name' do
        let(:dictionary_classes) { ['AbuseEvent'] }
        let(:factory_inferred_classes) { Set.new(['AbuseEvent']) }

        it 'does not register an offense' do
          expect_no_offenses(source)
        end
      end

      context 'when a factory name matches the underscored dictionary class' do
        let(:dictionary_classes) { ['Ci::BuildName'] }
        let(:factory_names) { Set.new(['ci_build_name']) }

        it 'does not register an offense' do
          expect_no_offenses(source)
        end
      end

      context 'with a partitioned table' do
        let(:dictionary_classes) { ['Ci::BuildName'] }
        let(:factory_names) { Set.new(['ci_build_name']) }

        it 'looks up the dictionary by the full table name including the p_ prefix' do
          expect_no_offenses(<<~RUBY)
          create_table :p_ci_build_names do |t|
            t.string :name
            t.timestamps
          end
          RUBY

          expect(described_class).to have_received(:dictionary_classes).with('p_ci_build_names')
        end
      end

      context 'when the dictionary lists no classes' do
        let(:dictionary_classes) { [] }
        let(:factory_classes) { Set.new(['Packages::Debian::FileMetadatum']) }

        it 'registers an offense' do
          expect_offense(<<~RUBY)
          create_table :packages_debian_file_metadata do |t|
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ No factory found for the table `packages_debian_file_metadata`.
            t.string :name
            t.timestamps
          end
          RUBY
        end
      end

      context 'when no factory matches the dictionary classes' do
        let(:dictionary_classes) { ['Packages::Debian::FileMetadatum'] }
        let(:factory_names) { Set.new(['some_other_factory']) }
        let(:factory_classes) { Set.new(['Some::OtherClass']) }
        let(:factory_inferred_classes) { Set.new(['SomeOtherFactory']) }

        it 'registers an offense' do
          expect_offense(<<~RUBY)
          create_table :packages_debian_file_metadata do |t|
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ No factory found for the table `packages_debian_file_metadata`.
            t.string :name
            t.timestamps
          end
          RUBY
        end
      end
    end
  end

  describe '#external_dependency_checksum' do
    it 'returns a SHA256 digest used by RuboCop to invalidate cache' do
      expect(cop.external_dependency_checksum).to match(/^\h{64}$/)
    end
  end

  describe '.factories' do
    let(:table_names) { %w[unnested_ce nested_ce_factory unnested_ee nested_ee_factory unnested_jh nested_jh_factory] }
    let(:factories) do
      %w[
        spec/factories/unnested_ce.rb
        spec/factories/nested/ce/factory.rb
        ee/spec/factories/unnested_ee.rb
        ee/spec/factories/nested/ee_factory.rb
        jh/spec/factories/unnested_jh.rb
        jh/spec/factories/nested_jh/factory.rb
      ]
    end

    before do
      allow(Dir).to receive(:glob).and_return(factories)
    end

    subject { described_class.factories }

    it { is_expected.to eq(table_names) }
  end

  describe '.factory_declarations' do
    let(:factory_source) do
      <<~RUBY
        FactoryBot.define do
          factory :debian_file_metadatum, class: 'Packages::Debian::FileMetadatum' do
            file_type { 'deb' }
          end

          factory :abuse_event do
            category { 'spam' }
          end

          factory :other_thing, class: ::Some::UnquotedClass do
            name { 'other' }
          end

          factory(:parenthesized) do
            name { 'paren' }
          end

          factory :symbol_class, class: :SymbolClass do
            name { 'symbol' }
          end
        end
      RUBY
    end

    before do
      clear_memo(:@factory_declarations)
      allow(Dir).to receive(:glob).and_return(['spec/factories/fake.rb'])
      allow(File).to receive(:read).with('spec/factories/fake.rb').and_return(factory_source)
    end

    after do
      clear_memo(:@factory_declarations)
    end

    it 'parses factory names, explicit classes, and inferred classes' do
      declarations = described_class.factory_declarations

      expect(declarations[:names]).to contain_exactly(
        'debian_file_metadatum', 'abuse_event', 'other_thing', 'parenthesized', 'symbol_class'
      )
      expect(declarations[:classes]).to contain_exactly(
        'Packages::Debian::FileMetadatum', 'Some::UnquotedClass', 'SymbolClass'
      )
      expect(declarations[:inferred_classes]).to include('AbuseEvent', 'DebianFileMetadatum', 'OtherThing')
    end
  end

  describe '.dictionary_classes' do
    before do
      clear_memo(:@dictionary_classes)
    end

    after do
      clear_memo(:@dictionary_classes)
    end

    it 'returns the classes from the table dictionary entry' do
      allow(File).to receive(:exist?).with('db/docs/some_table.yml').and_return(true)
      allow(YAML).to receive(:safe_load_file).with('db/docs/some_table.yml')
        .and_return({ 'classes' => ['Some::Model'] })

      expect(described_class.dictionary_classes('some_table')).to eq(['Some::Model'])
    end

    it 'returns an empty array when the dictionary entry does not exist' do
      allow(File).to receive(:exist?).with('db/docs/missing_table.yml').and_return(false)

      expect(described_class.dictionary_classes('missing_table')).to eq([])
    end

    it 'returns an empty array when the dictionary entry has no classes' do
      allow(File).to receive(:exist?).with('db/docs/no_classes.yml').and_return(true)
      allow(YAML).to receive(:safe_load_file).with('db/docs/no_classes.yml').and_return({ 'classes' => nil })

      expect(described_class.dictionary_classes('no_classes')).to eq([])
    end

    it 'returns an empty array when the dictionary entry cannot be parsed' do
      allow(File).to receive(:exist?).with('db/docs/broken.yml').and_return(true)
      allow(YAML).to receive(:safe_load_file).with('db/docs/broken.yml').and_raise(StandardError)

      expect(described_class.dictionary_classes('broken')).to eq([])
    end
  end

  def clear_memo(ivar)
    described_class.remove_instance_variable(ivar) if described_class.instance_variable_defined?(ivar)
  end
end
