# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Config::Entry::Include do
  subject(:include_entry) { described_class.new(config) }

  describe 'validations' do
    before do
      include_entry.compose!
    end

    context 'when value is a string' do
      let(:config) { 'test.yml' }

      it { is_expected.to be_valid }
    end

    context 'when value is hash' do
      context 'when using not allowed keys' do
        let(:config) do
          { not_allowed: 'key' }
        end

        it { is_expected.not_to be_valid }
      end

      context 'when using "local"' do
        let(:config) { { local: 'test.yml' } }

        it { is_expected.to be_valid }
      end

      context 'when using "file"' do
        let(:config) { { file: 'test.yml' } }

        it { is_expected.to be_valid }
      end

      context 'when using "template"' do
        let(:config) { { template: 'test.yml' } }

        it { is_expected.to be_valid }
      end

      context 'when using "artifact"' do
        context 'and specifying "job"' do
          let(:config) { { artifact: 'test.yml', job: 'generator' } }

          it { is_expected.to be_valid }
        end

        context 'without "job"' do
          let(:config) { { artifact: 'test.yml' } }

          it { is_expected.not_to be_valid }

          it 'has specific error' do
            expect(include_entry.errors)
              .to include('include config must specify the job where to fetch the artifact from')
          end
        end
      end

      context 'when using "project"' do
        context 'and specifying "ref" and "file"' do
          let(:config) { { project: 'my-group/my-pipeline-library', ref: 'master', file: 'test.yml' } }

          it { is_expected.to be_valid }
        end

        context 'without "ref"' do
          let(:config) { { project: 'my-group/my-pipeline-library', file: 'test.yml' } }

          it { is_expected.to be_valid }
        end

        context 'without "file"' do
          let(:config) { { project: 'my-group/my-pipeline-library' } }

          it { is_expected.not_to be_valid }

          it 'has specific error' do
            expect(include_entry.errors)
              .to include('include config must specify the file where to fetch the config from')
          end
        end
      end
    end

    context 'when value is something else' do
      let(:config) { 123 }

      it { is_expected.not_to be_valid }
    end
  end
end
