# frozen_string_literal: true

RSpec.shared_examples 'a BulkImports::Stage' do
  describe '#pipelines' do
    it 'only has pipelines with valid keys' do
      pipeline_keys = stage.pipelines.flat_map(&:keys).uniq
      allowed_keys = %i[pipeline stage minimum_source_version maximum_source_version]

      expect(pipeline_keys - allowed_keys).to be_empty
    end

    it 'only has pipelines with valid versions' do
      pipelines = stage.pipelines
      minimum_source_versions = pipelines.flat_map { |p| p[:minimum_source_version] }.compact
      maximum_source_versions = pipelines.flat_map { |p| p[:maximum_source_version] }.compact
      version_regex = /^(\d+)\.(\d+)\.0$/

      expect(minimum_source_versions.all? { |v| version_regex =~ v }).to be(true)
      expect(maximum_source_versions.all? { |v| version_regex =~ v }).to be(true)
    end

    context 'when stages are out of order in the config hash' do
      it 'lists all the pipelines ordered by stage' do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:config).and_return(
            {
              a: { stage: 2 },
              b: { stage: 1 },
              c: { stage: 0 },
              d: { stage: 2 }
            }
          )
        end

        expected_stages = stage.pipelines.collect { |p| p[:stage] }
        expect(expected_stages).to eq([0, 1, 2, 2])
      end
    end
  end
end
