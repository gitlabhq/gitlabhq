# frozen_string_literal: true
# rubocop:disable RSpec/VerifiedDoubles

require 'fast_spec_helper'
require 'rake'
require 'fileutils'

require_relative '../support/silence_stdout'
require_relative '../support/helpers/next_instance_of'
require_relative '../support/helpers/rake_helpers'
require_relative '../../rubocop/todo_dir'

RSpec.describe 'rubocop rake tasks', :silence_stdout do
  include RakeHelpers

  before do
    stub_const('Rails', double(:rails_env))
    allow(Rails).to receive(:env).and_return(double(production?: false))

    stub_const('ENV', ENV.to_hash.dup)

    Rake.application.rake_require 'tasks/rubocop'
  end

  describe 'todo:generate', :aggregate_failures do
    let(:tmp_dir) { Dir.mktmpdir }
    let(:rubocop_todo_dir) { File.join(tmp_dir, '.rubocop_todo') }
    let(:todo_dir) { RuboCop::TodoDir.new(rubocop_todo_dir) }

    around do |example|
      Dir.chdir(tmp_dir) do
        with_inflections do
          example.run
        end
      end
    end

    before do
      allow(RuboCop::TodoDir).to receive(:new).and_return(todo_dir)

      # This Ruby file will trigger the following 3 offenses.
      File.write('a.rb', <<~RUBY)
        a+b

      RUBY

      # Mimic GitLab's .rubocop_todo.yml avoids relying on RuboCop's
      # default.yml configuration.
      File.write('.rubocop.yml', <<~YAML)
        <% unless ENV['REVEAL_RUBOCOP_TODO'] == '1' %>
          <% Dir.glob('.rubocop_todo/**/*.yml').each do |rubocop_todo_yaml| %>
        - '<%= rubocop_todo_yaml %>'
          <% end %>
        - '.rubocop_todo.yml'
        <% end %>

        AllCops:
          NewCops: enable # Avoiding RuboCop warnings

        Layout/SpaceAroundOperators:
          Enabled: true

        Layout/TrailingEmptyLines:
          Enabled: true

        Lint/Syntax:
          Enabled: true

        Style/FrozenStringLiteralComment:
          Enabled: true
      YAML

      # Required to verify that we are revealing all TODOs via
      # ENV['REVEAL_RUBOCOP_TODO'] = '1'.
      # This file can be removed from specs after we've moved all offenses from
      # .rubocop_todo.yml to .rubocop_todo/**/*.yml.
      File.write('.rubocop_todo.yml', <<~YAML)
        # Too many offenses
        Layout/SpaceAroundOperators:
          Enabled: false
      YAML

      # Previous offense now fixed.
      todo_dir.write('Lint/Syntax', '')
    end

    after do
      FileUtils.remove_entry(tmp_dir)
    end

    context 'without arguments' do
      let(:run_task) { run_rake_task('rubocop:todo:generate') }

      it 'generates TODOs for all RuboCop rules' do
        expect { run_task }.to output(<<~OUTPUT).to_stdout
          Generating RuboCop TODOs with:
            rubocop --parallel --format RuboCop::Formatter::TodoFormatter

          This might take a while...
          Written to .rubocop_todo/layout/space_around_operators.yml
          Written to .rubocop_todo/layout/trailing_empty_lines.yml
          Written to .rubocop_todo/style/frozen_string_literal_comment.yml
        OUTPUT

        expect(rubocop_todo_dir_listing).to contain_exactly(
          'layout/space_around_operators.yml',
          'layout/trailing_empty_lines.yml',
          'style/frozen_string_literal_comment.yml'
        )
      end

      it 'sets acronyms for inflections' do
        run_task

        expect(ActiveSupport::Inflector.inflections.acronyms).to include(
          'rspec' => 'RSpec',
          'graphql' => 'GraphQL'
        )
      end
    end

    context 'with cop names as arguments' do
      let(:run_task) do
        cop_names = %w[
          Style/FrozenStringLiteralComment Layout/TrailingEmptyLines
          Lint/Syntax
        ]

        run_rake_task('rubocop:todo:generate', cop_names)
      end

      it 'generates TODOs for given RuboCop cops' do
        expect { run_task }.to output(<<~OUTPUT).to_stdout
          Generating RuboCop TODOs with:
            rubocop --parallel --format RuboCop::Formatter::TodoFormatter --only Layout/TrailingEmptyLines,Lint/Syntax,Style/FrozenStringLiteralComment

          This might take a while...
          Written to .rubocop_todo/layout/trailing_empty_lines.yml
          Written to .rubocop_todo/style/frozen_string_literal_comment.yml
        OUTPUT

        expect(rubocop_todo_dir_listing).to contain_exactly(
          'layout/trailing_empty_lines.yml',
          'style/frozen_string_literal_comment.yml'
        )
      end
    end

    private

    def rubocop_todo_dir_listing
      Dir.glob("#{rubocop_todo_dir}/**/*")
        .select { |path| File.file?(path) }
        .map { |path| path.delete_prefix("#{rubocop_todo_dir}/") }
    end

    def with_inflections
      original = ActiveSupport::Inflector::Inflections.instance_variable_get(:@__instance__)[:en]
      ActiveSupport::Inflector::Inflections.instance_variable_set(:@__instance__, en: original.dup)

      yield
    ensure
      ActiveSupport::Inflector::Inflections.instance_variable_set(:@__instance__, en: original)
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles
