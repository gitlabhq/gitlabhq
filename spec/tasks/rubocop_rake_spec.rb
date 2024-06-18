# frozen_string_literal: true
# rubocop:disable RSpec/VerifiedDoubles

require 'fast_spec_helper'
require 'tmpdir'
require 'fileutils'
require 'gitlab/rspec/next_instance_of'

require_relative '../support/silence_stdout'
require_relative '../support/matchers/abort_matcher'
require_relative '../../rubocop/formatter/todo_formatter'
require_relative '../../rubocop/todo_dir'
require_relative '../../rubocop/check_graceful_task'

RSpec.describe 'rubocop rake tasks', :silence_stdout do
  include NextInstanceOf

  before do
    stub_const('Rails', double(:rails_env))
    allow(Rails).to receive(:env).and_return(double(production?: false))

    stub_const('ENV', ENV.to_hash.dup)

    Rake.application.rake_require 'tasks/rubocop'
  end

  describe 'check:graceful' do
    let(:options) { %w[file.rb Cop/Name] }

    subject(:run_task) { run_rake_task('rubocop:check:graceful', *options) }

    before do
      allow_next_instance_of(RuboCop::CheckGracefulTask, $stdout) do |task|
        allow(task).to receive(:run).with(options).and_return(task_result)
      end
    end

    context 'with successful task result' do
      let(:task_result) { 0 }

      # We cannot use `abort_execution` because it's ignoring exit status `0`.
      # Rely on SystemExitDetected here.
      specify { run_task }

      it 'modifies ENV and deletes REVEAL_RUBOCOP_TODO key' do
        # There's ENV backup in before block.
        ENV['REVEAL_RUBOCOP_TODO'] = '0' # rubocop:disable RSpec/EnvAssignment

        run_task

        expect(ENV.key?('REVEAL_RUBOCOP_TODO')).to eq(false)
      end
    end

    context 'with non-successful task result' do
      let(:task_result) { 1 }

      specify { expect { run_task }.to abort_execution }
    end
  end

  describe 'todo:generate', :aggregate_failures do
    let(:tmp_dir) { Dir.mktmpdir }
    let(:rubocop_todo_dir) { File.join(tmp_dir, '.rubocop_todo') }
    let(:todo_dir) { RuboCop::TodoDir.new(rubocop_todo_dir) }

    around do |example|
      Dir.chdir(tmp_dir) do
        ::RuboCop::Formatter::TodoFormatter.with_base_directory(rubocop_todo_dir) do
          with_inflections do
            example.run
          end
        end
      end
    end

    before do
      # This Ruby file will trigger the following 3 offenses.
      File.write('a.rb', <<~RUBY)
        a+b

      RUBY

      # Mimicking GitLab's .rubocop_todo.yml avoids relying on RuboCop's
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

      it 'generates TODOs for all RuboCop rules', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/437144' do
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
