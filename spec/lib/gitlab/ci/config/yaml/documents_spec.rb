# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Yaml::Documents, feature_category: :pipeline_composition do
  let(:documents) { described_class.new(yaml_documents) }

  describe '#header' do
    context 'when there are at least 2 documents and the first document has a `spec` keyword' do
      let(:yaml_documents) { [::Gitlab::Config::Loader::Yaml.new('spec:'), ::Gitlab::Config::Loader::Yaml.new('job:')] }

      it 'returns the header' do
        expect(documents.header).to eq(spec: nil)
      end
    end

    context 'when there are fewer than 2 documents' do
      let(:yaml_documents) { [::Gitlab::Config::Loader::Yaml.new('job:')] }

      it 'returns nil' do
        expect(documents.header).to be_nil
      end
    end

    context 'when there are at least 2 documents and the first document does not have a `spec` keyword' do
      let(:yaml_documents) do
        [::Gitlab::Config::Loader::Yaml.new('job1:'), ::Gitlab::Config::Loader::Yaml.new('job2:')]
      end

      it 'returns nil' do
        expect(documents.header).to be_nil
      end
    end
  end

  describe '#content' do
    context 'when there is a header' do
      let(:yaml_documents) { [::Gitlab::Config::Loader::Yaml.new('spec:'), ::Gitlab::Config::Loader::Yaml.new('job:')] }

      it 'returns the unparsed content of the last document' do
        expect(documents.content).to eq('job:')
      end
    end

    context 'when there is no header' do
      let(:yaml_documents) { [::Gitlab::Config::Loader::Yaml.new('job:')] }

      it 'returns the unparsed content of the first document' do
        expect(documents.content).to eq('job:')
      end
    end
  end
end
