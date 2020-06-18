# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Build::Releaser do
  subject { described_class.new(config: config[:release]).script }

  describe '#script' do
    context 'all nodes' do
      let(:config) do
        {
          release: {
            name: 'Release $CI_COMMIT_SHA',
            description: 'Created using the release-cli $EXTRA_DESCRIPTION',
            tag_name: 'release-$CI_COMMIT_SHA',
            ref: '$CI_COMMIT_SHA'
          }
        }
      end

      it 'generates the script' do
        expect(subject).to eq('release-cli create --name "Release $CI_COMMIT_SHA" --description "Created using the release-cli $EXTRA_DESCRIPTION" --tag-name "release-$CI_COMMIT_SHA" --ref "$CI_COMMIT_SHA"')
      end
    end

    context 'individual nodes' do
      using RSpec::Parameterized::TableSyntax

      where(:node_name, :node_value, :result) do
        'name' | 'Release $CI_COMMIT_SHA' | 'release-cli create --name "Release $CI_COMMIT_SHA"'
        'description' | 'Release-cli $EXTRA_DESCRIPTION' | 'release-cli create --description "Release-cli $EXTRA_DESCRIPTION"'
        'tag_name' | 'release-$CI_COMMIT_SHA' | 'release-cli create --tag-name "release-$CI_COMMIT_SHA"'
        'ref' | '$CI_COMMIT_SHA' | 'release-cli create --ref "$CI_COMMIT_SHA"'
      end

      with_them do
        let(:config) do
          {
            release: {
              node_name => node_value
            }
          }
        end

        it 'generates the script' do
          expect(subject).to eq(result)
        end
      end
    end
  end
end
