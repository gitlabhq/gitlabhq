# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../rubocop/cop_todo'

RSpec.describe RuboCop::CopTodo, feature_category: :tooling do
  let(:cop_name) { 'Cop/Rule' }

  subject(:cop_todo) { described_class.new(cop_name) }

  describe '#initialize' do
    it 'initializes a cop todo' do
      expect(cop_todo).to have_attributes(
        cop_name: cop_name,
        files: be_empty,
        offense_count: 0,
        previously_disabled: false,
        grace_period: false
      )
    end
  end

  describe '#record' do
    it 'records offenses' do
      cop_todo.record('a.rb', 1)
      cop_todo.record('b.rb', 2)

      expect(cop_todo).to have_attributes(
        files: contain_exactly('a.rb', 'b.rb'),
        offense_count: 3
      )
    end
  end

  describe '#add_files' do
    it 'adds files' do
      cop_todo.add_files(%w[a.rb b.rb])
      cop_todo.add_files(%w[a.rb])
      cop_todo.add_files(%w[])

      expect(cop_todo).to have_attributes(
        files: contain_exactly('a.rb', 'b.rb'),
        offense_count: 0
      )
    end
  end

  describe '#autocorrectable?' do
    subject { cop_todo.autocorrectable? }

    context 'when found in rubocop registry' do
      before do
        fake_cop = double(:cop, support_autocorrect?: autocorrectable) # rubocop:disable RSpec/VerifiedDoubles

        allow(described_class).to receive(:find_cop_by_name)
          .with(cop_name).and_return(fake_cop)
      end

      context 'when autocorrectable' do
        let(:autocorrectable) { true }

        it { is_expected.to be_truthy }
      end

      context 'when not autocorrectable' do
        let(:autocorrectable) { false }

        it { is_expected.to be_falsey }
      end
    end

    context 'when not found in rubocop registry' do
      before do
        allow(described_class).to receive(:find_cop_by_name)
          .with(cop_name).and_return(nil).and_call_original
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#generate?' do
    subject { cop_todo.generate? }

    context 'when empty todo' do
      it { is_expected.to eq(false) }
    end

    context 'when previously disabled' do
      before do
        cop_todo.previously_disabled = true
      end

      it { is_expected.to eq(true) }
    end

    context 'when in grace period' do
      before do
        cop_todo.grace_period = true
      end

      it { is_expected.to eq(true) }
    end

    context 'with offenses recorded' do
      before do
        cop_todo.record('a.rb', 1)
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '#to_yaml' do
    subject(:yaml) { cop_todo.to_yaml }

    context 'when autocorrectable' do
      before do
        allow(cop_todo).to receive(:autocorrectable?).and_return(true)
      end

      specify do
        expect(yaml).to eq(<<~YAML)
          ---
          # Cop supports --autocorrect.
          #{cop_name}:
        YAML
      end
    end

    context 'when previously disabled' do
      specify do
        cop_todo.record('a.rb', 1)
        cop_todo.record('b.rb', 2)
        cop_todo.previously_disabled = true

        expect(yaml).to eq(<<~YAML)
          ---
          #{cop_name}:
            # Offense count: 3
            # Temporarily disabled due to too many offenses
            Enabled: false
            Exclude:
              - 'a.rb'
              - 'b.rb'
        YAML
      end
    end

    context 'with grace period' do
      specify do
        cop_todo.record('a.rb', 1)
        cop_todo.record('b.rb', 2)
        cop_todo.grace_period = true

        expect(yaml).to eq(<<~YAML)
          ---
          #{cop_name}:
            Details: grace period
            Exclude:
              - 'a.rb'
              - 'b.rb'
        YAML
      end
    end

    context 'with multiple files' do
      before do
        cop_todo.record('a.rb', 0)
        cop_todo.record('c.rb', 0)
        cop_todo.record('b.rb', 0)
      end

      it 'sorts excludes alphabetically' do
        expect(yaml).to eq(<<~YAML)
        ---
        #{cop_name}:
          Exclude:
            - 'a.rb'
            - 'b.rb'
            - 'c.rb'
        YAML
      end
    end
  end
end
