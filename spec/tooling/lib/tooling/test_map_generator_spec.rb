# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/test_map_generator'
require_relative '../../../support/helpers/file_read_helpers'

RSpec.describe Tooling::TestMapGenerator do
  include FileReadHelpers

  subject { described_class.new }

  describe '#parse' do
    let(:yaml1) do
      <<~YAML
        ---
        :type: Crystalball::ExecutionMap
        :commit: a7d57d333042f3b0334b2f8a282354eef7365976
        :timestamp: 1602668405
        :version:
        ---
        "./spec/factories_spec.rb[1]":
        - lib/gitlab/current_settings.rb
        - lib/feature.rb
        - lib/gitlab/marginalia.rb
      YAML
    end

    let(:yaml2) do
      <<~YAML
        ---
        :type: Crystalball::ExecutionMap
        :commit: 74056e8d9cf3773f43faa1cf5416f8779c8284c8
        :timestamp: 1602671965
        :version:
        ---
        "./spec/models/project_spec.rb[1]":
        - lib/gitlab/current_settings.rb
        - lib/feature.rb
        - lib/gitlab/marginalia.rb
      YAML
    end

    let(:pathname) { instance_double(Pathname) }

    before do
      stub_file_read('yaml1.yml', content: yaml1)
      stub_file_read('yaml2.yml', content: yaml2)
    end

    context 'with single yaml' do
      let(:expected_mapping) do
        {
          'lib/gitlab/current_settings.rb' => [
            'spec/factories_spec.rb'
          ],
          'lib/feature.rb' => [
            'spec/factories_spec.rb'
          ],
          'lib/gitlab/marginalia.rb' => [
            'spec/factories_spec.rb'
          ]
        }
      end

      it 'parses crystalball data into test mapping' do
        subject.parse('yaml1.yml')

        expect(subject.mapping.keys).to match_array(expected_mapping.keys)
      end

      it 'stores test files without example uid' do
        subject.parse('yaml1.yml')

        expected_mapping.each do |file, tests|
          expect(subject.mapping[file]).to match_array(tests)
        end
      end
    end

    context 'with multiple yamls' do
      let(:expected_mapping) do
        {
          'lib/gitlab/current_settings.rb' => [
            'spec/factories_spec.rb',
            'spec/models/project_spec.rb'
          ],
          'lib/feature.rb' => [
            'spec/factories_spec.rb',
            'spec/models/project_spec.rb'
          ],
          'lib/gitlab/marginalia.rb' => [
            'spec/factories_spec.rb',
            'spec/models/project_spec.rb'
          ]
        }
      end

      it 'parses crystalball data into test mapping' do
        subject.parse(%w[yaml1.yml yaml2.yml])

        expect(subject.mapping.keys).to match_array(expected_mapping.keys)
      end

      it 'stores test files without example uid' do
        subject.parse(%w[yaml1.yml yaml2.yml])

        expected_mapping.each do |file, tests|
          expect(subject.mapping[file]).to match_array(tests)
        end
      end
    end
  end
end
