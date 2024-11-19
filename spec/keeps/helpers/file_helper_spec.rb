# frozen_string_literal: true

require 'spec_helper'
require './keeps/helpers/file_helper'

RSpec.describe Keeps::Helpers::FileHelper, feature_category: :tooling do
  let(:helper) { described_class.new(temp_file.path) }
  let(:temp_file) { Tempfile.new(filename) }
  let(:unparsed_content) do
    <<~RUBY
      # Migration type +class+
      # frozen_string_literal: true

      # See https://docs.gitlab.com/ee/development/migration_style_guide.html
      # for more information on how to write migrations for GitLab.

      =begin
        This migration adds
        a new column to project
      =end
      class AddColToProjects < Gitlab::Database::Migration[2.2]
        milestone '16.11' # Inline comment

        def change
          add_column :projects, :bool_col, :boolean, default: false, null: false # adds a new column
        end
      end# Another inline comment
    RUBY
  end

  before do
    temp_file.write(unparsed_content)
    temp_file.rewind
    temp_file.close
  end

  after do
    temp_file.unlink
  end

  describe '#replace_method_content' do
    before do
      helper.replace_method_content(:change, content, strip_comments_from_file: strip_content)
    end

    context 'when striping comments from file' do
      let(:filename) { 'migration_two.txt' }
      let(:strip_content) { true }
      let(:content) do
        <<~RUBY
          disable_ddl_transaction!

            def up
              add_column :projects, :bool_col, :boolean, default: false, null: false # adds a boolean type col
            end

            def down
              remove_column :projects, :bool_col, if_exists: true
            end
        RUBY
      end

      let(:parsed_file) do
        <<~RUBY
          # frozen_string_literal: true

          class AddColToProjects < Gitlab::Database::Migration[2.2]
            milestone '16.11'

            disable_ddl_transaction!

            def up
              add_column :projects, :bool_col, :boolean, default: false, null: false # adds a boolean type col
            end

            def down
              remove_column :projects, :bool_col, if_exists: true
            end

          end
        RUBY
      end

      it 'parses the file as expected' do
        expect(temp_file.open.read).to eq(parsed_file)
      end
    end

    context 'when keeping comments in the file' do
      let(:filename) { 'migration_two.txt' }
      let(:strip_content) { false }
      let(:content) do
        <<~RUBY
          disable_ddl_transaction!

            def up
              add_column :projects, :bool_col, :boolean, default: false, null: false
            end

            def down
              remove_column :projects, :bool_col, if_exists: true
            end
        RUBY
      end

      let(:parsed_file) do
        <<~RUBY
          # Migration type +class+
          # frozen_string_literal: true

          # See https://docs.gitlab.com/ee/development/migration_style_guide.html
          # for more information on how to write migrations for GitLab.

          =begin
            This migration adds
            a new column to project
          =end
          class AddColToProjects < Gitlab::Database::Migration[2.2]
            milestone '16.11' # Inline comment

            disable_ddl_transaction!

            def up
              add_column :projects, :bool_col, :boolean, default: false, null: false
            end

            def down
              remove_column :projects, :bool_col, if_exists: true
            end

          end# Another inline comment
        RUBY
      end

      it 'parses the file as expected' do
        expect(temp_file.open.read).to eq(parsed_file)
      end
    end
  end

  describe '#replace_as_string' do
    let(:filename) { 'file.txt' }
    let(:new_milestone) { '17.5' }
    let(:parsed_file) do
      <<~RUBY
        # Migration type +class+
        # frozen_string_literal: true

        # See https://docs.gitlab.com/ee/development/migration_style_guide.html
        # for more information on how to write migrations for GitLab.

        =begin
          This migration adds
          a new column to project
        =end
        class AddColToProjects < Gitlab::Database::Migration[2.2]
          milestone #{new_milestone} # Inline comment

          def change
            add_column :projects, :bool_col, :boolean, default: false, null: false # adds a new column
          end
        end# Another inline comment
      RUBY
    end

    before do
      described_class.def_node_matcher(:milestone_node, '`(send nil? :milestone $(str _) ...)')
    end

    it 'parses the file as expected' do
      expect(helper.replace_as_string(helper.milestone_node, new_milestone)).to eq(parsed_file)
    end
  end
end
