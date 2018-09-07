require 'rails_helper'

describe Gitlab::Ci::ExternalFiles::Mapper do
  describe '.fetch_paths' do
    context 'when includes is defined as string' do
      let(:values) { { includes: '/vendor/gitlab-ci-yml/non-existent-file.yml', image: 'ruby:2.2'} }

      it 'returns an array' do
        expect(described_class.fetch_paths(values)).to be_an(Array)
      end

      it 'returns ExternalFile instances' do
        expect(described_class.fetch_paths(values).first).to be_an_instance_of(::Gitlab::Ci::ExternalFiles::ExternalFile)
      end
    end

    context 'when includes is defined as an array' do
      let(:values) { { includes: ['https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml', '/vendor/gitlab-ci-yml/template.yml'], image: 'ruby:2.2'} }
      it 'returns an array' do
        expect(described_class.fetch_paths(values)).to be_an(Array)
      end

      it 'returns ExternalFile instances' do
        paths = described_class.fetch_paths(values)
        paths.each do |path|
          expect(path).to be_an_instance_of(::Gitlab::Ci::ExternalFiles::ExternalFile)
        end
      end
    end

    context 'when includes is not defined' do
      let(:values) { { image: 'ruby:2.2'} }

      it 'returns an empty array' do
        expect(described_class.fetch_paths(values)).to be_empty
      end
    end
  end
end
