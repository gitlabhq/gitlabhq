# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles

require 'fast_spec_helper'

require 'fileutils'
require 'stringio'
require 'tmpdir'

require_relative '../../../rubocop/formatter/todo_formatter'
require_relative '../../../rubocop/todo_dir'

RSpec.describe RuboCop::Formatter::TodoFormatter, feature_category: :tooling do
  let(:stdout) { StringIO.new }
  let(:tmp_dir) { Dir.mktmpdir }
  let(:real_tmp_dir) { File.join(tmp_dir, 'real') }
  let(:symlink_tmp_dir) { File.join(tmp_dir, 'symlink') }
  let(:rubocop_todo_dir) { "#{symlink_tmp_dir}/.rubocop_todo" }
  let(:todo_dir) { RuboCop::TodoDir.new(rubocop_todo_dir) }

  subject(:formatter) { described_class.new(stdout) }

  around do |example|
    FileUtils.mkdir(real_tmp_dir)
    FileUtils.symlink(real_tmp_dir, symlink_tmp_dir)

    Dir.chdir(symlink_tmp_dir) do
      described_class.with_base_directory(rubocop_todo_dir) do
        example.run
      end
    end
  end

  after do
    FileUtils.remove_entry(tmp_dir)
  end

  context 'with offenses detected' do
    let(:offense) { fake_offense('A/Offense') }
    let(:offense_too_many) { fake_offense('B/TooManyOffenses') }
    let(:offense_autocorrect) { fake_offense('B/AutoCorrect') }

    before do
      stub_rubocop_registry(
        'A/Offense' => { autocorrectable: false },
        'B/AutoCorrect' => { autocorrectable: true }
      )
    end

    def run_formatter
      formatter.started(%w[a.rb b.rb c.rb d.rb])
      formatter.file_finished('c.rb', [offense_too_many])
      formatter.file_finished('a.rb', [offense_too_many, offense, offense_too_many])
      formatter.file_finished('b.rb', [])
      formatter.file_finished('d.rb', [offense_autocorrect])
      formatter.finished(%w[a.rb b.rb c.rb d.rb])
    end

    it 'outputs its actions' do
      run_formatter

      expect(stdout.string).to eq(<<~OUTPUT)
        Written to .rubocop_todo/a/offense.yml
        Written to .rubocop_todo/b/auto_correct.yml
        Written to .rubocop_todo/b/too_many_offenses.yml
      OUTPUT
    end

    it 'creates YAML files', :aggregate_failures do
      run_formatter

      expect(rubocop_todo_dir_listing).to contain_exactly(
        'a/offense.yml', 'b/auto_correct.yml', 'b/too_many_offenses.yml'
      )

      expect(todo_yml('A/Offense')).to eq(<<~YAML)
        ---
        A/Offense:
          Exclude:
            - 'a.rb'
      YAML

      expect(todo_yml('B/AutoCorrect')).to eq(<<~YAML)
        ---
        # Cop supports --autocorrect.
        B/AutoCorrect:
          Exclude:
            - 'd.rb'
      YAML

      expect(todo_yml('B/TooManyOffenses')).to eq(<<~YAML)
        ---
        B/TooManyOffenses:
          Exclude:
            - 'a.rb'
            - 'c.rb'
      YAML
    end

    context 'with empty exclusions' do
      before do
        todo_dir.write('C/EmptyList', <<~YAML)
          ---
          C/EmptyList:
            Exclude:
        YAML

        todo_dir.inspect_all
      end

      it 'does not raise an error' do
        expect { run_formatter }.not_to raise_error
      end
    end

    context 'with existing HAML exclusions' do
      before do
        todo_dir.write('B/TooManyOffenses', <<~YAML)
          ---
          B/TooManyOffenses:
            Exclude:
              - 'd.rb'
              - 'app/views/project.html.haml'
              - 'app/views/project.haml'
              - 'app/views/project.text.haml'
              - 'app/views/unrelated.html.haml.ext'
        YAML

        todo_dir.inspect_all
      end

      it 'does not remove them' do
        run_formatter

        expect(todo_yml('B/TooManyOffenses')).to eq(<<~YAML)
          ---
          B/TooManyOffenses:
            Exclude:
              - 'a.rb'
              - 'app/views/project.haml'
              - 'app/views/project.html.haml'
              - 'app/views/project.text.haml'
              - 'c.rb'
        YAML
      end
    end

    context 'when cop previously not explicitly disabled' do
      before do
        todo_dir.write('B/TooManyOffenses', <<~YAML)
          ---
          B/TooManyOffenses:
            Exclude:
              - 'x.rb'
        YAML

        todo_dir.inspect_all
      end

      it 'does not disable cop' do
        run_formatter

        expect(todo_yml('B/TooManyOffenses')).to eq(<<~YAML)
          ---
          B/TooManyOffenses:
            Exclude:
              - 'a.rb'
              - 'c.rb'
        YAML
      end
    end

    context 'when cop previously explicitly disabled in rubocop_todo/' do
      before do
        todo_dir.write('B/TooManyOffenses', <<~YAML)
          ---
          B/TooManyOffenses:
            Enabled: false
            Exclude:
              - 'x.rb'
        YAML

        todo_dir.inspect_all
      end

      it 'keeps cop disabled' do
        run_formatter

        expect(todo_yml('B/TooManyOffenses')).to eq(<<~YAML)
          ---
          B/TooManyOffenses:
            # Offense count: 3
            # Temporarily disabled due to too many offenses
            Enabled: false
            Exclude:
              - 'a.rb'
              - 'c.rb'
        YAML
      end
    end

    context 'when cop previously explicitly disabled in rubocop_todo.yml' do
      before do
        File.write('.rubocop_todo.yml', <<~YAML)
          ---
          B/TooManyOffenses:
            Enabled: false
            Exclude:
              - 'x.rb'
        YAML

        todo_dir.inspect_all
      end

      it 'keeps cop disabled' do
        run_formatter

        expect(todo_yml('B/TooManyOffenses')).to eq(<<~YAML)
          ---
          B/TooManyOffenses:
            # Offense count: 3
            # Temporarily disabled due to too many offenses
            Enabled: false
            Exclude:
              - 'a.rb'
              - 'c.rb'
        YAML
      end
    end

    context 'with grace period' do
      let(:yaml) do
        <<~YAML
          ---
          B/TooManyOffenses:
            Details: grace period
            Exclude:
              - 'x.rb'
        YAML
      end

      shared_examples 'keeps grace period' do
        it 'keeps Details: grace period' do
          run_formatter

          expect(todo_yml('B/TooManyOffenses')).to eq(<<~YAML)
            ---
            B/TooManyOffenses:
              Details: grace period
              Exclude:
                - 'a.rb'
                - 'c.rb'
          YAML
        end
      end

      context 'in rubocop_todo/' do
        before do
          todo_dir.write('B/TooManyOffenses', yaml)
          todo_dir.inspect_all
        end

        it_behaves_like 'keeps grace period'
      end

      context 'in rubocop_todo.yml' do
        before do
          File.write('.rubocop_todo.yml', yaml)
        end

        it_behaves_like 'keeps grace period'
      end

      context 'with invalid details value' do
        let(:yaml) do
          <<~YAML
            ---
            B/TooManyOffenses:
              Details: something unknown
              Exclude:
                - 'x.rb'
          YAML
        end

        it 'ignores the details and warns' do
          File.write('.rubocop_todo.yml', yaml)

          expect { run_formatter }
            .to output(%r{B/TooManyOffenses: Unhandled value "something unknown" for `Details` key.})
            .to_stderr

          expect(todo_yml('B/TooManyOffenses')).to eq(<<~YAML)
            ---
            B/TooManyOffenses:
              Exclude:
                - 'a.rb'
                - 'c.rb'
          YAML
        end
      end

      context 'and previously disabled' do
        let(:yaml) do
          <<~YAML
            ---
            B/TooManyOffenses:
              Enabled: false
              Details: grace period
              Exclude:
                - 'x.rb'
          YAML
        end

        it 'raises an exception' do
          File.write('.rubocop_todo.yml', yaml)

          expect { run_formatter }
            .to raise_error(RuntimeError, 'B/TooManyOffenses: Cop must be enabled to use `Details: grace period`.')
        end
      end
    end

    context 'with cop configuration in both .rubocop_todo/ and .rubocop_todo.yml' do
      before do
        todo_dir.write('B/TooManyOffenses', <<~YAML)
          ---
          B/TooManyOffenses:
            Exclude:
              - 'a.rb'
        YAML

        todo_dir.write('A/Offense', <<~YAML)
          ---
          A/Offense:
            Exclude:
              - 'a.rb'
        YAML

        todo_dir.inspect_all

        File.write('.rubocop_todo.yml', <<~YAML)
          ---
          B/TooManyOffenses:
            Exclude:
              - 'x.rb'
          A/Offense:
            Exclude:
              - 'y.rb'
        YAML
      end

      it 'raises an error' do
        expect { run_formatter }.to raise_error(RuntimeError, <<~TXT)
          Multiple configurations found for cops:
          - A/Offense
          - B/TooManyOffenses
        TXT
      end
    end
  end

  context 'without offenses detected' do
    before do
      todo_dir.write('A/Cop', yaml) if yaml
      todo_dir.inspect_all

      formatter.started(%w[a.rb b.rb])
      formatter.file_finished('a.rb', [])
      formatter.file_finished('b.rb', [])
      formatter.finished(%w[a.rb b.rb])

      todo_dir.delete_inspected
    end

    context 'without existing TODOs' do
      let(:yaml) { nil }

      it 'does not output anything' do
        expect(stdout.string).to eq('')
      end

      it 'does not write any YAML files' do
        expect(rubocop_todo_dir_listing).to be_empty
      end
    end

    context 'with existing TODOs' do
      context 'when existing offenses only' do
        let(:yaml) do
          <<~YAML
            ---
            A/Cop:
              Exclude:
                - x.rb
          YAML
        end

        it 'does not output anything' do
          expect(stdout.string).to eq('')
        end

        it 'does not write any YAML files' do
          expect(rubocop_todo_dir_listing).to be_empty
        end
      end

      context 'when in grace period' do
        let(:yaml) do
          <<~YAML
            ---
            A/Cop:
              Details: grace period
              Exclude:
                - x.rb
          YAML
        end

        it 'outputs its actions' do
          expect(stdout.string).to eq(<<~OUTPUT)
            Written to .rubocop_todo/a/cop.yml
          OUTPUT
        end

        it 'creates YAML file with Details only', :aggregate_failures do
          expect(rubocop_todo_dir_listing).to contain_exactly(
            'a/cop.yml'
          )

          expect(todo_yml('A/Cop')).to eq(<<~YAML)
            ---
            A/Cop:
              Details: grace period
          YAML
        end
      end
    end
  end

  context 'without files to inspect' do
    before do
      formatter.started([])
      formatter.finished([])
    end

    it 'does not output anything' do
      expect(stdout.string).to eq('')
    end

    it 'does not write any YAML files' do
      expect(rubocop_todo_dir_listing).to be_empty
    end
  end

  private

  def rubocop_todo_dir_listing
    Dir.glob("#{rubocop_todo_dir}/**/*")
      .select { |path| File.file?(path) }
      .map { |path| path.delete_prefix("#{rubocop_todo_dir}/") }
  end

  def todo_yml(cop_name)
    todo_dir.read(cop_name)
  end

  def fake_offense(cop_name)
    double(:offense, cop_name: cop_name)
  end

  def stub_rubocop_registry(cops)
    allow(RuboCop::CopTodo).to receive(:find_cop_by_name)
      .with(String).and_return(nil).and_call_original

    cops.each do |cop_name, attributes|
      allow(RuboCop::CopTodo).to receive(:find_cop_by_name)
        .with(cop_name).and_return(fake_cop(**attributes))
    end
  end

  def fake_cop(autocorrectable:)
    double(:cop, support_autocorrect?: autocorrectable)
  end
end

# rubocop:enable RSpec/VerifiedDoubles
