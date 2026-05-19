# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/prevent_large_blob_in_database'

RSpec.describe RuboCop::Cop::Migration::PreventLargeBlobInDatabase, feature_category: :database do
  let(:max_size) { 4_096 }
  let(:cop_config) { { 'MaxSize' => max_size } }

  let(:msg) { 'Text column limit of 131072 exceeds the maximum allowed size of 4096 characters.[...]' }

  context 'when in migration' do
    before do
      allow(cop).to receive_messages(in_migration?: true, time_enforced?: true)
    end

    context 'when text column limit exceeds MaxSize' do
      it 'registers an offense for `t.text ... limit: N` inside `create_table`' do
        expect_offense(<<~RUBY)
          def up
            create_table :examples do |t|
              t.text :content, limit: 131_072
                ^^^^ #{msg}
            end
          end
        RUBY
      end

      it 'registers an offense for `t.text_limit` inside `create_table`' do
        expect_offense(<<~RUBY)
          def up
            create_table :examples do |t|
              t.text :content
              t.text_limit :content, 131_072
                ^^^^^^^^^^ #{msg}
            end
          end
        RUBY
      end

      it 'registers an offense for `add_text_limit`' do
        expect_offense(<<~RUBY)
          def up
            add_text_limit :examples, :content, 131_072
            ^^^^^^^^^^^^^^ #{msg}
          end
        RUBY
      end

      it 'registers offenses for multiple violations in the same migration' do
        expect_offense(<<~RUBY)
          def up
            create_table :examples do |t|
              t.text :content, limit: 131_072
                ^^^^ #{msg}
            end

            add_text_limit :examples, :other_content, 131_072
            ^^^^^^^^^^^^^^ #{msg}
          end
        RUBY
      end
    end

    it 'does not register an offense when the limit equals MaxSize' do
      expect_no_offenses(<<~RUBY)
        def up
          create_table :examples do |t|
            t.text :content, limit: 4_096
          end

          add_text_limit :examples, :other_content, 4_096
        end
      RUBY
    end

    it 'does not register an offense when `t.text` is used without a limit' do
      expect_no_offenses(<<~RUBY)
        def up
          create_table :examples do |t|
            t.text :content
          end
        end
      RUBY
    end

    context 'with a custom MaxSize' do
      let(:max_size) { 1_024 }

      it 'registers an offense for limits exceeding the custom MaxSize' do
        msg = 'Text column limit of 2048 exceeds the maximum allowed size of 1024 characters.[...]'

        expect_offense(<<~RUBY)
          def up
            add_text_limit :examples, :content, 2_048
            ^^^^^^^^^^^^^^ #{msg}
          end
        RUBY
      end

      it 'does not register an offense for limits within the custom MaxSize' do
        expect_no_offenses(<<~RUBY)
          def up
            add_text_limit :examples, :content, 1_024
          end
        RUBY
      end
    end

    it 'does not register an offense for `encrypted_` columns regardless of limit' do
      expect_no_offenses(<<~RUBY)
        def up
          create_table :examples do |t|
            t.text :encrypted_content, limit: 131_072
          end

          add_text_limit :examples, :encrypted_other, 131_072
        end
      RUBY
    end

    it 'resolves a same-file column name constant before the encrypted check' do
      expect_no_offenses(<<~RUBY)
        COLUMN = :encrypted_content

        def up
          create_table :examples do |t|
            t.text COLUMN, limit: 131_072
          end

          add_text_limit :examples, COLUMN, 131_072
        end
      RUBY
    end

    it 'still flags a same-file column name constant that is not encrypted' do
      expect_offense(<<~RUBY)
        COLUMN = :content

        def up
          add_text_limit :examples, COLUMN, 131_072
          ^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end

    it 'does not register an offense when the column name cannot be statically resolved' do
      expect_no_offenses(<<~RUBY)
        def up
          add_text_limit :examples, UNRESOLVED, 131_072
        end
      RUBY
    end

    context 'on `down`' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def down
            create_table :examples do |t|
              t.text :content, limit: 131_072
            end

            add_text_limit :examples, :other_content, 131_072
          end
        RUBY
      end

      it 'flags `up` but not `down` in the same migration' do
        expect_offense(<<~RUBY)
          def up
            add_text_limit :examples, :content, 131_072
            ^^^^^^^^^^^^^^ #{msg}
          end

          def down
            add_text_limit :examples, :content, 131_072
          end
        RUBY
      end
    end

    context 'when the limit is supplied via a same-file integer constant' do
      it 'resolves the constant and registers an offense when it exceeds MaxSize' do
        expect_offense(<<~RUBY)
          MAX_TEXT_SIZE = 131_072

          def up
            add_text_limit :examples, :content, MAX_TEXT_SIZE
            ^^^^^^^^^^^^^^ #{msg}
          end
        RUBY
      end

      it 'does not register an offense when the resolved constant is within MaxSize' do
        expect_no_offenses(<<~RUBY)
          SAFE_LIMIT = 1024

          def up
            add_text_limit :examples, :content, SAFE_LIMIT
          end
        RUBY
      end
    end

    it 'does not register an offense when the limit cannot be statically resolved' do
      expect_no_offenses(<<~RUBY)
        def up
          add_text_limit :examples, :content, UNRESOLVED_LIMIT
        end
      RUBY
    end
  end

  context 'when outside of migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(false)
    end

    it 'does not register an offense' do
      expect_no_offenses('def up; add_text_limit :examples, :content, 131_072; end')
    end
  end

  context 'when the migration is older than the enforcement date' do
    before do
      allow(cop).to receive_messages(in_migration?: true, time_enforced?: false)
    end

    it 'does not register an offense' do
      expect_no_offenses('def up; add_text_limit :examples, :content, 131_072; end')
    end
  end
end
