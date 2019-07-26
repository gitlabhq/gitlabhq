# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Jobs do
  let(:entry) { described_class.new(config) }

  describe '.all_types' do
    subject { described_class.all_types }

    it { is_expected.to include(::Gitlab::Ci::Config::Entry::Hidden) }
    it { is_expected.to include(::Gitlab::Ci::Config::Entry::Job) }
  end

  describe '.find_type' do
    using RSpec::Parameterized::TableSyntax

    let(:config) do
      {
        '.hidden_job'.to_sym => { script: 'something' },
        regular_job: { script: 'something' },
        invalid_job: 'text'
      }
    end

    where(:name, :type) do
      :'.hidden_job'    | ::Gitlab::Ci::Config::Entry::Hidden
      :regular_job      | ::Gitlab::Ci::Config::Entry::Job
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
      let(:config) { { rspec: { script: 'rspec' } } }

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
            expect(entry.errors).to include "jobs config should contain valid jobs"
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

      let(:config) do
        { rspec: { script: 'rspec' },
          spinach: { script: 'spinach' },
          '.hidden'.to_sym => {} }
      end

      describe '#value' do
        it 'returns key value' do
          expect(entry.value).to eq(
            rspec: { name: :rspec,
                    script: %w[rspec],
                    ignore: false,
                    stage: 'test',
                    only: { refs: %w[branches tags] },
                    variables: {} },
            spinach: { name: :spinach,
                      script: %w[spinach],
                      ignore: false,
                      stage: 'test',
                      only: { refs: %w[branches tags] },
                      variables: {} })
        end
      end

      describe '#descendants' do
        it 'creates valid descendant nodes' do
          expect(entry.descendants.count).to eq 3
          expect(entry.descendants.first(2))
            .to all(be_an_instance_of(Gitlab::Ci::Config::Entry::Job))
          expect(entry.descendants.last)
            .to be_an_instance_of(Gitlab::Ci::Config::Entry::Hidden)
        end
      end

      describe '#value' do
        it 'returns value of visible jobs only' do
          expect(entry.value.keys).to eq [:rspec, :spinach]
        end
      end
    end
  end
end
