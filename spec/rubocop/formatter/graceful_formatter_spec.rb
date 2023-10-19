# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'
require 'stringio'

require_relative '../../../rubocop/formatter/graceful_formatter'
require_relative '../../../rubocop/todo_dir'

RSpec.describe RuboCop::Formatter::GracefulFormatter, :isolated_environment do
  # Set by :isolated_environment
  let(:todo_dir) { RuboCop::TodoDir.new("#{Dir.pwd}/.rubocop_todo") }
  let(:stdout) { StringIO.new }

  subject(:formatter) { described_class.new(stdout) }

  shared_examples 'summary reporting' do |inspected:, offenses: 0, silenced: 0|
    it "reports summary with #{inspected} inspected, #{offenses} offenses, #{silenced} silenced" do
      expect(stdout.string)
        .to match(/Inspecting #{inspected} files/)
        .and match(/#{inspected} files inspected/)

      if offenses > 0
        expect(stdout.string).to match(/Offenses:/)
        expect(stdout.string).to match(/#{offenses} offenses detected/)
      else
        expect(stdout.string).not_to match(/Offenses:/)
        expect(stdout.string).to match(/no offenses detected/)
      end

      if silenced > 0
        expect(stdout.string).to match(/Silenced offenses:/)
        expect(stdout.string).to match(/#{silenced} offenses silenced/)
      else
        expect(stdout.string).not_to match(/Silenced offenses:/)
        expect(stdout.string).not_to match(/offenses silenced/)
      end
    end
  end

  context 'with offenses' do
    let(:offense1) { fake_offense('Cop1') }
    let(:offense2) { fake_offense('Cop2') }

    before do
      FileUtils.touch('.rubocop_todo.yml')

      File.write('.rubocop.yml', <<~YAML)
        inherit_from:
          <% Dir.glob('.rubocop_todo/**/*.yml').each do |rubocop_todo_yaml| %>
          - '<%= rubocop_todo_yaml %>'
          <% end %>
          - '.rubocop_todo.yml'

        AllCops:
          NewCops: enable # Avoiding RuboCop warnings
      YAML

      # These cops are unknown and would raise an validation error
      allow(RuboCop::Cop::Registry.global).to receive(:contains_cop_matching?)
        .and_return(true)
    end

    context 'with active only' do
      before do
        formatter.started(%w[a.rb b.rb])
        formatter.file_finished('a.rb', [offense1])
        formatter.file_finished('b.rb', [offense2])
        formatter.finished(%w[a.rb b.rb])
      end

      it_behaves_like 'summary reporting', inspected: 2, offenses: 2
    end

    context 'with silenced only' do
      before do
        todo_dir.write('Cop1', <<~YAML)
        ---
        Cop1:
          Details: grace period
        YAML

        File.write('.rubocop_todo.yml', <<~YAML)
        ---
        Cop2:
          Details: grace period
        YAML

        formatter.started(%w[a.rb b.rb])
        formatter.file_finished('a.rb', [offense1])
        formatter.file_finished('b.rb', [offense2])
        formatter.finished(%w[a.rb b.rb])
      end

      it_behaves_like 'summary reporting', inspected: 2, silenced: 2
    end

    context 'with active and silenced' do
      before do
        todo_dir.write('Cop1', <<~YAML)
        ---
        Cop1:
          Details: grace period
        YAML

        formatter.started(%w[a.rb b.rb])
        formatter.file_finished('a.rb', [offense1, offense2])
        formatter.file_finished('b.rb', [offense2, offense1, offense1])
        formatter.finished(%w[a.rb b.rb])
      end

      it_behaves_like 'summary reporting', inspected: 2, offenses: 2, silenced: 3
    end
  end

  context 'without offenses' do
    before do
      formatter.started(%w[a.rb b.rb])
      formatter.file_finished('a.rb', [])
      formatter.file_finished('b.rb', [])
      formatter.finished(%w[a.rb b.rb])
    end

    it_behaves_like 'summary reporting', inspected: 2
  end

  context 'without files to inspect' do
    before do
      formatter.started([])
      formatter.finished([])
    end

    it_behaves_like 'summary reporting', inspected: 0
  end

  context 'with missing @total_offense_count' do
    it 'raises an error' do
      formatter.started(%w[a.rb])

      if formatter.instance_variable_defined?(:@total_offense_count)
        formatter.remove_instance_variable(:@total_offense_count)
      end

      expect do
        formatter.finished(%w[a.rb])
      end.to raise_error(/RuboCop has changed its internals/)
    end
  end

  describe '.adjusted_exit_status' do
    using RSpec::Parameterized::TableSyntax

    success = RuboCop::CLI::STATUS_SUCCESS
    offenses = RuboCop::CLI::STATUS_OFFENSES
    error = RuboCop::CLI::STATUS_ERROR

    subject { described_class.adjusted_exit_status(status) }

    where(:active_offenses, :status, :adjusted_status) do
      0 | success  | success
      0 | offenses | success
      1 | offenses | offenses
      0 | error    | error
      1 | error    | error
      # impossible cases
      1 | success  | success
    end

    with_them do
      around do |example|
        described_class.active_offenses = active_offenses
        example.run
      ensure
        described_class.active_offenses = 0
      end

      it { is_expected.to eq(adjusted_status) }
    end
  end

  describe '.grace_period?' do
    let(:cop_name) { 'Cop/Name' }

    subject { described_class.grace_period?(cop_name, config) }

    context 'with Details in config' do
      let(:config) { { 'Details' => 'grace period' } }

      it { is_expected.to eq(true) }
    end

    context 'with unknown value for Details in config' do
      let(:config) { { 'Details' => 'unknown' } }

      specify do
        expect { is_expected.to eq(false) }
          .to output(/#{cop_name}: Unhandled value "unknown" for `Details` key./)
          .to_stderr
      end
    end

    context 'with empty config' do
      let(:config) { {} }

      it { is_expected.to eq(false) }
    end

    context 'without Details in config' do
      let(:config) { { 'Exclude' => false } }

      it { is_expected.to eq(false) }
    end
  end

  describe '.grace_period_key_value' do
    subject { described_class.grace_period_key_value }

    it { is_expected.to eq('Details: grace period') }
  end

  def fake_offense(cop_name)
    # rubocop:disable RSpec/VerifiedDoubles
    double(
      :offense,
      cop_name: cop_name,
      corrected?: false,
      correctable?: false,
      severity: double(:severity, name: :convention, code: :C),
      line: 5,
      column: 23,
      real_column: 23,
      corrected_with_todo?: false,
      message: "#{cop_name} message",
      location: double(:location, source_line: 'line', first_line: 1, last_line: 1, single_line?: true),
      highlighted_area: double(:highlighted_area, begin_pos: 1, size: 2, source_buffer: 'line', source: 'i')
    )
    # rubocop:enable RSpec/VerifiedDoubles
  end
end
