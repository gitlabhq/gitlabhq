# frozen_string_literal: true

require 'spec_helper'
require 'tty-prompt'

RSpec.describe Gitlab::Database::Diagnostics::Console::Runner, feature_category: :database do
  let(:buffer) { StringIO.new }

  def build_view(title, counts: {}, raises: nil, body: nil)
    Class.new do
      define_singleton_method(:title) { title }

      define_method(:initialize) do |databases:, printer:|
        @databases = databases
        @printer = printer
      end

      define_method(:run) do
        raise raises if raises

        @printer.line(body) if body

        counts
      end
    end
  end

  def run(views)
    described_class.new(database_names: %w[main ci], output: buffer, views: views).run
  end

  def rendered
    buffer.string.split("\n")
  end

  before do
    allow(Gitlab::Database::DatabaseInformation)
      .to receive(:execute).with(database_names: %w[main ci]).and_return({ databases: {} })
  end

  describe '#run' do
    it 'prints a header naming the databases' do
      run([build_view('Clean')])

      expect(rendered.first(2)).to eq([
        'Database diagnostics',
        'Databases: main, ci'
      ])
    end

    it 'collects the payload once for every view' do
      expect(Gitlab::Database::DatabaseInformation).to receive(:execute).once.and_return({ databases: {} })

      run([build_view('One'), build_view('Two')])
    end

    context 'when every view is clean' do
      it 'returns nil and reports no issues' do
        expect(run([build_view('Clean'), build_view('Also clean')])).to be_nil

        expect(rendered).to include('Clean ... OK', 'Also clean ... OK', 'No issues found.')
      end
    end

    context 'when a view reports warnings only' do
      it 'returns warning' do
        expect(run([build_view('Noisy', counts: { 'warning' => 2 })])).to eq('warning')

        expect(rendered).to include('Noisy ... 2 warnings', 'Completed with 2 warnings.')
      end
    end

    context 'when a view reports an error' do
      it 'returns error and totals the counts across views' do
        views = [
          build_view('Bad', counts: { 'error' => 1, 'warning' => 1 }),
          build_view('Noisy', counts: { 'warning' => 1 })
        ]

        expect(run(views)).to eq('error')

        expect(rendered).to include(
          'Bad ... 1 error, 1 warning',
          'Noisy ... 1 warning',
          'Completed with 1 error, 2 warnings.'
        )
      end
    end

    context 'when a view raises' do
      let(:views) do
        [
          build_view('Broken', raises: ArgumentError.new('boom')),
          build_view('Clean')
        ]
      end

      it 'records an error, reports the exception and still runs the other views' do
        expect(run(views)).to eq('error')

        expect(rendered).to include(
          'Broken ... failed',
          '   ArgumentError: boom',
          'Clean ... OK'
        )
      end
    end

    context 'when collecting the payload raises' do
      it 'reports it against the view and exits with an error' do
        allow(Gitlab::Database::DatabaseInformation)
          .to receive(:execute).and_raise(ActiveRecord::ConnectionNotEstablished, 'down')

        expect(run([build_view('Clean')])).to eq('error')

        expect(rendered).to include('Clean ... failed')
      end
    end

    it 'prints the check details after the summary' do
      run([build_view('Clean', body: 'Clean details')])

      expect(rendered.index('Clean details')).to be > rendered.index('No issues found.')
    end

    context 'when interactive' do
      let(:paged) { [] }

      let(:menu_recorder) do
        Class.new do
          attr_reader :choices

          def initialize
            @choices = {}
          end

          def choice(label, value)
            @choices[label] = value
          end
        end
      end

      def build_prompt(picks)
        remaining = picks.dup

        prompt = instance_double(TTY::Prompt)
        allow(prompt).to receive(:select) do |_question, **_options, &menu_block|
          menu = menu_recorder.new
          menu_block.call(menu)
          menu.choices.fetch(remaining.shift)
        end

        prompt
      end

      def interactive_run(views, picks, pager: ->(body) { paged << body })
        described_class.new(
          database_names: %w[main ci], output: buffer, views: views,
          interactive: true, prompt: build_prompt(picks), pager: pager
        ).run
      end

      it 'prints only the summary when the user quits immediately', :aggregate_failures do
        result = interactive_run([build_view('Noisy', counts: { 'warning' => 1 }, body: 'Noisy details')], %w[Quit])

        expect(result).to eq('warning')
        expect(rendered).to include('Noisy ... 1 warning')
        expect(paged).to be_empty
      end

      it 'pages the details of the selected check', :aggregate_failures do
        views = [
          build_view('Noisy', counts: { 'warning' => 1 }, body: 'Noisy details'),
          build_view('Clean', body: 'Clean details')
        ]

        interactive_run(views, %w[Noisy Quit])

        expect(paged.join).to include('Noisy details')
        expect(paged.join).not_to include('Clean details')
        expect(rendered).not_to include('Noisy details')
      end

      it 'prints the details when the pager is unavailable' do
        views = [build_view('Noisy', body: 'Noisy details')]

        interactive_run(views, %w[Noisy Quit], pager: ->(_body) { raise Errno::ENOENT })

        expect(rendered).to include('Noisy details')
      end
    end

    it 'runs every view inside a primary-only session', :aggregate_failures do
      scoped_sessions = Gitlab::Database::LoadBalancing::SessionMap
        .with_sessions(Gitlab::Database::LoadBalancing.base_models)

      allow(scoped_sessions).to receive(:use_primary).and_call_original
      allow(Gitlab::Database::LoadBalancing::SessionMap)
        .to receive(:with_sessions).with(Gitlab::Database::LoadBalancing.base_models)
        .and_return(scoped_sessions)

      expect(run([build_view('Clean')])).to be_nil

      expect(scoped_sessions).to have_received(:use_primary)
      expect(rendered).to include('Clean ... OK')
    end
  end
end
