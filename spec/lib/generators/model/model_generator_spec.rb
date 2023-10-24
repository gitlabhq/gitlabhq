# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Model::ModelGenerator do
  let(:args) { ['ModelGeneratorTestFoo'] }
  let(:options) { { 'migration' => true, 'timestamps' => true, 'indexes' => true, 'test_framework' => :rspec } }
  let(:temp_dir) { Dir.mktmpdir }
  let(:migration_file_path) { Dir.glob(File.join(temp_dir, 'db/migrate/*create_model_generator_test_foos.rb')).first }
  let(:model_file_path) { File.join(temp_dir, 'app/models/model_generator_test_foo.rb') }
  let(:spec_file_path) { File.join(temp_dir, 'spec/models/model_generator_test_foo_spec.rb') }

  subject { described_class.new(args, options, { destination_root: temp_dir }) }

  context 'when generating a model' do
    after do
      FileUtils.rm_rf(temp_dir)
    end

    before do
      allow(Gitlab).to receive(:current_milestone).and_return('16.5')
    end

    it 'creates the model file with the right content' do
      subject.invoke_all

      expect(File).to exist(model_file_path)
      mock_model_file_content = File.read(File.expand_path('./mocks/model_file.txt', __dir__))
      model_file_content = File.read(model_file_path)
      expect(model_file_content).to eq(mock_model_file_content)
    end

    it 'creates the migration file with the right content' do
      subject.invoke_all

      expect(File).to exist(migration_file_path)
      mock_migration_file_content = File.read(File.expand_path('./mocks/migration_file.txt', __dir__))
      migration_file_content = File.read(migration_file_path)
      expect(migration_file_content).to eq(mock_migration_file_content)
    end

    it 'creates the spec file with the right content' do
      subject.invoke_all

      expect(File).to exist(spec_file_path)
      mock_spec_file_content = File.read(File.expand_path('./mocks/spec_file.txt', __dir__))
      spec_file_content = File.read(spec_file_path)
      expect(spec_file_content).to eq(mock_spec_file_content)
    end
  end
end
