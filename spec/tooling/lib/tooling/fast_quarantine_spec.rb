# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/fast_quarantine'
require 'tempfile'

RSpec.describe Tooling::FastQuarantine, feature_category: :tooling do
  attr_accessor :fast_quarantine_file

  around do |example|
    self.fast_quarantine_file = Tempfile.new('fast_quarantine_file')

    # See https://ruby-doc.org/stdlib-1.9.3/libdoc/tempfile/rdoc/
    #     Tempfile.html#class-Tempfile-label-Explicit+close
    begin
      example.run
    ensure
      fast_quarantine_file.close
      fast_quarantine_file.unlink
    end
  end

  let(:fast_quarantine_path) { fast_quarantine_file.path }
  let(:fast_quarantine_file_content) { '' }
  let(:instance) do
    described_class.new(fast_quarantine_path: fast_quarantine_path)
  end

  before do
    File.write(fast_quarantine_path, fast_quarantine_file_content)
  end

  describe '#initialize' do
    context 'when fast_quarantine_path does not exist' do
      it 'prints a warning' do
        allow(File).to receive(:exist?).and_return(false)

        expect { instance }.to output("#{fast_quarantine_path} doesn't exist!\n").to_stderr
      end
    end

    context 'when fast_quarantine_path exists' do
      it 'does not raise an error' do
        expect { instance }.not_to raise_error
      end
    end
  end

  describe '#identifiers' do
    before do
      allow(File).to receive(:read).and_call_original
    end

    context 'when the fast quarantine file is empty' do
      let(:fast_quarantine_file_content) { '' }

      it 'returns []' do
        expect(instance.identifiers).to eq([])
      end
    end

    context 'when the fast quarantine file is not empty' do
      let(:fast_quarantine_file_content) { "./spec/foo_spec.rb\nspec/foo_spec.rb:42\n./spec/baz_spec.rb[1:2:3]" }

      it 'returns parsed and sanitized lines' do
        expect(instance.identifiers).to eq(%w[
          spec/foo_spec.rb
          spec/foo_spec.rb:42
          spec/baz_spec.rb[1:2:3]
        ])
      end

      context 'when reading the file raises an error' do
        before do
          allow(File).to receive(:read).with(fast_quarantine_path).and_raise('')
        end

        it 'returns []' do
          expect(instance.identifiers).to eq([])
        end
      end

      describe 'memoization' do
        it 'memoizes the identifiers list' do
          expect(File).to receive(:read).with(fast_quarantine_path).once.and_call_original

          instance.identifiers

          # calling #identifiers again doesn't call File.read
          instance.identifiers
        end
      end
    end
  end

  describe '#skip_example?' do
    let(:fast_quarantine_file_content) { "./spec/foo_spec.rb\nspec/bar_spec.rb:42\n./spec/baz_spec.rb[1:2:3]" }
    let(:example_id) { './spec/foo_spec.rb[1:2:3]' }
    let(:example_metadata) { {} }
    let(:example) { instance_double(RSpec::Core::Example, id: example_id, metadata: example_metadata) }

    describe 'skipping example by id' do
      let(:example_id) { './spec/baz_spec.rb[1:2:3]' }

      it 'skips example by id' do
        expect(instance.skip_example?(example)).to be_truthy
      end
    end

    describe 'skipping example by line' do
      context 'when example location matches' do
        let(:example_metadata) do
          { location: './spec/bar_spec.rb:42' }
        end

        it 'skips example by line' do
          expect(instance.skip_example?(example)).to be_truthy
        end
      end

      context 'when example group location matches' do
        let(:example_metadata) do
          {
            example_group: { location: './spec/bar_spec.rb:42' }
          }
        end

        it 'skips example by line' do
          expect(instance.skip_example?(example)).to be_truthy
        end
      end

      context 'when nested parent example group location matches' do
        let(:example_metadata) do
          {
            example_group: {
              parent_example_group: {
                parent_example_group: {
                  parent_example_group: { location: './spec/bar_spec.rb:42' }
                }
              }
            }
          }
        end

        it 'skips example by line' do
          expect(instance.skip_example?(example)).to be_truthy
        end
      end
    end

    describe 'skipping example by file' do
      context 'when example file_path matches' do
        let(:example_metadata) do
          { file_path: './spec/foo_spec.rb' }
        end

        it 'skips example by file' do
          expect(instance.skip_example?(example)).to be_truthy
        end
      end

      context 'when example group file_path matches' do
        let(:example_metadata) do
          {
            example_group: { file_path: './spec/foo_spec.rb' }
          }
        end

        it 'skips example by file' do
          expect(instance.skip_example?(example)).to be_truthy
        end
      end

      context 'when nested parent example group file_path matches' do
        let(:example_metadata) do
          {
            example_group: {
              parent_example_group: {
                parent_example_group: {
                  parent_example_group: { file_path: './spec/foo_spec.rb' }
                }
              }
            }
          }
        end

        it 'skips example by file' do
          expect(instance.skip_example?(example)).to be_truthy
        end
      end
    end
  end
end
