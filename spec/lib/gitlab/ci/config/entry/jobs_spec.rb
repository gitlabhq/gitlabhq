# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Jobs do
  let(:entry) { described_class.new(config) }

  let(:config) do
    {
      '.hidden_job'.to_sym => { script: 'something' },
      '.hidden_bridge'.to_sym => { trigger: 'my/project' },
      regular_job: { script: 'something' },
      my_trigger: { trigger: 'my/project' }
    }
  end

  describe '.all_types' do
    subject { described_class.all_types }

    it { is_expected.to include(::Gitlab::Ci::Config::Entry::Hidden) }
    it { is_expected.to include(::Gitlab::Ci::Config::Entry::Job) }
    it { is_expected.to include(::Gitlab::Ci::Config::Entry::Bridge) }
  end

  describe '.find_type' do
    using RSpec::Parameterized::TableSyntax

    where(:name, :type) do
      :'.hidden_job'    | ::Gitlab::Ci::Config::Entry::Hidden
      :'.hidden_bridge' | ::Gitlab::Ci::Config::Entry::Hidden
      :regular_job      | ::Gitlab::Ci::Config::Entry::Job
      :my_trigger       | ::Gitlab::Ci::Config::Entry::Bridge
      :invalid_job      | nil
    end

    subject { described_class.find_type(name, config[name]) }

    with_them do
      it { is_expected.to eq(type) }
    end
  end

  describe 'validations' do
    before do
      entry.compose!
    end

    context 'when entry config value is correct' do
      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry value is not correct' do
      describe '#errors' do
        context 'incorrect config value type' do
          let(:config) { ['incorrect'] }

          it 'returns error about incorrect type' do
            expect(entry.errors)
              .to include 'jobs config should be a hash'
          end
        end

        context 'when job is invalid' do
          let(:config) { { rspec: nil } }

          it 'reports error' do
            expect(entry.errors).to include 'jobs rspec config should implement a script: or a trigger: keyword'
          end
        end

        context 'when no visible jobs present' do
          let(:config) { { '.hidden'.to_sym => { script: [] } } }

          it 'returns error about no visible jobs defined' do
            expect(entry.errors)
              .to include 'jobs config should contain at least one visible job'
          end
        end
      end
    end
  end

  describe '.compose!' do
    context 'when valid job entries composed' do
      before do
        entry.compose!
      end

      describe '#value' do
        it 'returns key value' do
          expect(entry.value).to eq(
            my_trigger: {
              ignore: false,
              name: :my_trigger,
              only: { refs: %w[branches tags] },
              stage: 'test',
              trigger: { project: 'my/project' },
              variables: {},
              job_variables: {},
              root_variables_inheritance: true,
              scheduling_type: :stage
            },
            regular_job: {
              ignore: false,
              name: :regular_job,
              only: { refs: %w[branches tags] },
              script: ['something'],
              stage: 'test',
              variables: {},
              job_variables: {},
              root_variables_inheritance: true,
              scheduling_type: :stage
            })
        end
      end

      describe '#descendants' do
        it 'creates valid descendant nodes' do
          expect(entry.descendants.map(&:class)).to eq [
            Gitlab::Ci::Config::Entry::Hidden,
            Gitlab::Ci::Config::Entry::Hidden,
            Gitlab::Ci::Config::Entry::Job,
            Gitlab::Ci::Config::Entry::Bridge
          ]
        end
      end

      describe '#value' do
        it 'returns value of visible jobs only' do
          expect(entry.value.keys).to eq [:regular_job, :my_trigger]
        end
      end
    end
  end
end
