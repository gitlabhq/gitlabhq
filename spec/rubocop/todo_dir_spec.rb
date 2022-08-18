# frozen_string_literal: true

require 'fast_spec_helper'

require 'active_support/inflector/inflections'
require 'fileutils'
require 'tmpdir'

require_relative '../../rubocop/todo_dir'

RSpec.describe RuboCop::TodoDir do
  let(:todo_dir) { described_class.new(directory) }
  let(:directory) { Dir.mktmpdir }
  let(:cop_name) { 'RSpec/VariableInstance' }
  let(:cop_name_underscore) { ActiveSupport::Inflector.underscore(cop_name) }
  let(:yaml_path) { "#{File.join(directory, cop_name_underscore)}.yml" }

  around do |example|
    Dir.chdir(directory) do
      example.run
    end
  end

  after do
    FileUtils.remove_entry(directory)
  end

  describe '#initialize' do
    context 'when passing inflector' do
      let(:fake_inflector) { double(:inflector) } # rubocop:disable RSpec/VerifiedDoubles
      let(:todo_dir) { described_class.new(directory, inflector: fake_inflector) }

      before do
        allow(fake_inflector).to receive(:underscore)
          .with(cop_name)
          .and_return(cop_name_underscore)
      end

      it 'calls .underscore' do
        todo_dir.write(cop_name, 'a')

        expect(fake_inflector).to have_received(:underscore)
      end
    end
  end

  describe '#read' do
    let(:content) { 'a' }

    subject { todo_dir.read(cop_name) }

    context 'when file exists' do
      before do
        todo_dir.write(cop_name, content)
      end

      it { is_expected.to eq(content) }
    end

    context 'when file is missing' do
      it { is_expected.to be_nil }
    end
  end

  describe '#write' do
    let(:content) { 'a' }

    subject { todo_dir.write(cop_name, content) }

    it { is_expected.to eq(yaml_path) }

    it 'writes content to YAML file' do
      subject

      expect(File.read(yaml_path)).to eq(content)
    end
  end

  describe '#inspect' do
    subject { todo_dir.inspect(cop_name) }

    context 'with existing YAML file' do
      before do
        todo_dir.write(cop_name, 'a')
      end

      it { is_expected.to eq(true) }

      it 'moves YAML file to .inspect' do
        subject

        expect(File).not_to exist(yaml_path)
        expect(File).to exist("#{yaml_path}.inspect")
      end
    end

    context 'with missing YAML file' do
      it { is_expected.to eq(false) }
    end
  end

  describe '#inspect_all' do
    subject { todo_dir.inspect_all }

    context 'with YAML files' do
      before do
        todo_dir.write(cop_name, 'a')
        todo_dir.write('Other/Rule', 'a')
        todo_dir.write('Very/Nested/Rule', 'a')
      end

      it { is_expected.to eq(3) }

      it 'moves all YAML files to .inspect' do
        subject

        expect(Dir.glob('**/*.yml')).to be_empty
        expect(Dir.glob('**/*.yml.inspect').size).to eq(3)
      end
    end

    context 'with non-YAML files' do
      before do
        File.write('file', 'a')
        File.write('file.txt', 'a')
        File.write('file.yaml', 'a') # not .yml
      end

      it { is_expected.to eq(0) }

      it 'does not move non-YAML files' do
        subject

        expect(Dir.glob('**/*'))
          .to contain_exactly('file', 'file.txt', 'file.yaml')
      end
    end

    context 'without files' do
      it { is_expected.to eq(0) }
    end
  end

  describe '#list_inspect' do
    let(:content) { 'a' }

    subject { todo_dir.list_inspect }

    context 'when file exists and is being inspected' do
      before do
        todo_dir.write(cop_name, content)
        todo_dir.inspect_all
      end

      it do
        is_expected.to contain_exactly("#{yaml_path}.inspect")
      end
    end

    context 'when file exists but not being inspected' do
      before do
        todo_dir.write(cop_name, content)
      end

      it { is_expected.to be_empty }
    end

    context 'when file is missing' do
      it { is_expected.to be_empty }
    end
  end

  describe '#delete_inspected' do
    subject { todo_dir.delete_inspected }

    context 'with YAML files' do
      before do
        todo_dir.write(cop_name, 'a')
        todo_dir.write('Other/Rule', 'a')
        todo_dir.write('Very/Nested/Rule', 'a')
        todo_dir.inspect_all
      end

      it { is_expected.to eq(3) }

      it 'deletes all .inspected YAML files' do
        subject

        expect(Dir.glob('**/*.yml.inspect')).to be_empty
      end
    end

    context 'with non-YAML files' do
      before do
        File.write('file.inspect', 'a')
        File.write('file.txt.inspect', 'a')
        File.write('file.yaml.inspect', 'a') # not .yml
      end

      it { is_expected.to eq(0) }

      it 'does not delete non-YAML files' do
        subject

        expect(Dir.glob('**/*')).to contain_exactly(
          'file.inspect', 'file.txt.inspect', 'file.yaml.inspect')
      end
    end

    context 'without files' do
      it { is_expected.to eq(0) }
    end
  end
end
