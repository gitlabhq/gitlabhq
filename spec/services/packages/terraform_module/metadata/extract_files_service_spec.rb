# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::TerraformModule::Metadata::ExtractFilesService, feature_category: :package_registry do
  let(:service) { described_class.new(archive_file) }

  describe '#execute' do
    subject { service.execute }

    let(:metadata) do
      {
        root: {
          inputs: [
            {
              'name' => 'filename',
              'type' => 'string',
              'default' => 'null',
              'description' => 'The filename of the file to be created.'
            },
            {
              'name' => 'text',
              'type' => 'string',
              'default' => 'null',
              'description' => 'The text contents of the file to be created.'
            }
          ],
          readme: "# Gitlab Local File\n\nThis repository contains a [Terraform](https://www.terraform.io/) " \
                  "module to create a local file.\n\n## How do you use this module?\n\nThis folder defines " \
                  "a [Terraform module](https://www.terraform.io/docs/modules/usage.html), which you can use in " \
                  "your\ncode by adding a `module` configuration and setting its `source` parameter to the URL of " \
                  "this folder:\n\n```hcl\nmodule \"gitlab_local_file\" {\n  source = " \
                  "\"gitlab.com/mattkasa/terraform-modules/gitlab-local-file?ref=master\"\n\n  " \
                  "text = \"Hello World\"\n  filename = \"hello\"\n}\n```\n",
          outputs: [{ 'name' => 'bytes' }],
          resources: ['local_file.file'],
          dependencies: { modules: [], providers: [] }
        }
      }
    end

    shared_examples 'raising extraction error' do |error_message|
      it { expect { subject }.to raise_error(described_class::ExtractionError, /#{error_message}/) }
    end

    shared_examples 'extracting metadata' do
      it { is_expected.to be_success }
      it { expect(subject.payload).to eq(metadata) }
    end

    shared_examples 'extracting metadata from README files only' do
      let(:metadata) { super().tap { |metadata| metadata[:root].slice!(:readme) } }

      before do
        allow_next_instance_of(::Packages::TerraformModule::Metadata::ParseHclFileService) do |parser|
          allow(parser).to receive(:execute).and_raise(StandardError)
        end
      end

      it_behaves_like 'extracting metadata'
    end

    shared_examples 'raising too many files error' do
      context 'with too many files' do
        before do
          stub_const("#{described_class}::MAX_PROCESSED_FILES_COUNT", 1)
        end

        it_behaves_like 'raising extraction error', 'Too many files'
      end
    end

    shared_examples 'aggregating metadata' do
      context 'with submodules & examples' do
        let(:parsed_content) do
          {
            root: { resources: ['local_file.file'],
                    dependencies: { modules: [{ 'name' => 'mod' }], providers: [] } },
            submodules: {
              'submodule1' => {
                readme: 'submodule1 README.md',
                resources: ['local_file1.file'],
                dependencies: { modules: [{ 'name' => 'mod1', 'source' => 'mod1/local', 'version' => '2.0.0' }],
                                providers: [{ 'name' => 'aws', 'source' => 'hashicorp/aws', 'version' => '3.1' }] }
              }
            },
            examples: {
              'example1' => {
                readme: 'example1 README.md',
                resources: ['local_file2.file'],
                dependencies: { modules: [{ 'name' => 'mod2', 'source' => 'mod2/local', 'version' => '3.0.0' }],
                                providers: [{ 'name' => 'goog', 'source' => 'hashicorp/goog', 'version' => '3.2' }] }
              }
            }
          }
        end

        before do
          allow_next_instance_of(::Packages::TerraformModule::Metadata::ProcessFileService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.success(payload: parsed_content))
          end
        end

        it 'aggregates metadata into root' do
          expect(subject).to be_success
          expect(subject.payload).to eq({
            root: {
              resources: ['local_file.file', 'local_file1.file', 'local_file2.file'],
              dependencies: {
                modules: [{ 'name' => 'mod' },
                  { 'name' => 'mod1', 'source' => 'mod1/local', 'version' => '2.0.0' },
                  { 'name' => 'mod2', 'source' => 'mod2/local', 'version' => '3.0.0' }],
                providers: [{ 'name' => 'aws', 'source' => 'hashicorp/aws', 'version' => '3.1' },
                  { 'name' => 'goog', 'source' => 'hashicorp/goog', 'version' => '3.2' }]
              }
            },
            submodules: parsed_content[:submodules],
            examples: parsed_content[:examples].transform_values { |v| v.except(:resources, :dependencies) }
          })
        end

        context 'with missing attributes in submodules & examples' do
          let(:parsed_content) { super().merge(submodules: { 'submodule1' => { readme: 'submodule1 README.md' } }) }

          it 'aggregates metadata into root' do
            expect(subject).to be_success
            expect(subject.payload).to eq({
              root: {
                resources: ['local_file.file', 'local_file2.file'],
                dependencies: {
                  modules: [{ 'name' => 'mod' },
                    { 'name' => 'mod2', 'source' => 'mod2/local', 'version' => '3.0.0' }],
                  providers: [{ 'name' => 'goog', 'source' => 'hashicorp/goog', 'version' => '3.2' }]
                }
              },
              submodules: { 'submodule1' => { readme: 'submodule1 README.md' } },
              examples: parsed_content[:examples].transform_values { |v| v.except(:resources, :dependencies) }
            })
          end
        end
      end
    end

    context 'when processing a tar archive' do
      let_it_be(:package_file) { build(:package_file, :terraform_module) }
      let(:archive_file) { Gem::Package::TarReader.new(Zlib::GzipReader.open(package_file.file.path)) }

      it_behaves_like 'extracting metadata'

      context 'with a wrong entry size', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446108' do
        before do
          allow(::File).to receive(:size).and_return(described_class::MAX_FILE_SIZE + 1)
        end

        it_behaves_like 'raising extraction error', 'metadata file has the wrong entry size'
      end

      it_behaves_like 'raising too many files error'
      it_behaves_like 'aggregating metadata'

      context 'with relative path module (its path starts with ./)' do
        let(:package_file) do
          build(
            :package_file,
            :terraform_module,
            file_fixture: expand_fixture_path('packages/terraform_module/module-relative-path.tgz')
          )
        end

        let(:archive_file) { Gem::Package::TarReader.new(Zlib::GzipReader.open(package_file.file.path)) }

        it_behaves_like 'extracting metadata'
      end

      context 'when a processing error occurs druing HCL file parsing' do
        it_behaves_like 'extracting metadata from README files only'
      end
    end

    context 'when processing a zip archive' do
      let_it_be(:package_file) { build(:package_file, :terraform_module, zip: true) }
      let(:archive_file) { Zip::File.open(package_file.file.path) }

      it_behaves_like 'extracting metadata'

      context 'with a wrong entry size' do
        before do
          allow_next_instance_of(Zip::Entry) do |instance|
            allow(instance).to receive(:extract).and_raise(Zip::EntrySizeError)
          end
        end

        it_behaves_like 'raising extraction error', 'metadata file has the wrong entry size'
      end

      it_behaves_like 'raising too many files error'
      it_behaves_like 'aggregating metadata'

      context 'when a processing error occurs druing HCL file parsing' do
        it_behaves_like 'extracting metadata from README files only'
      end
    end

    context 'for getting module_type from path' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:archive_file) { Zip::File.new('', create: true) }

      where(:path, :module_type) do
        'README'                              | :root
        'README.md'                           | :root
        './root/README.md'                    | :root
        'main.tf'                             | :root
        './main.tf'                           | :root
        'modules/foo.tf'                      | :root
        'examples/foo.tf'                     | :root
        'module_name/modules.tf'              | :root
        'module_name/examples.tf'             | :root
        'modules/module_name/main.tf'         | :submodule
        './modules/module_name/main.tf'       | :submodule
        './root/modules/module_name/main.tf'  | :submodule
        'root/modules/module_name/main.tf'    | :submodule
        'examples/module_name/main.tf'        | :example
        './examples/module_name/main.tf'      | :example
        'root/examples/module_name/main.tf'   | :example
        './root/examples/module_name/main.tf' | :example
        'module_name/modules/main.tf'         | nil
        'example_name/examples/main.tf'       | nil
        'main/module_name/modules.tf'         | nil
        'main/example_name/examples.tf'       | nil
        './module_name/modules/foo.tf'        | nil
        './module_name/examples/foo.tf'       | nil
        'submodules/module_name/main.tf'      | nil
        'invalid/path/file.tf'                | nil
      end

      with_them do
        it 'returns correct module_type' do
          expect(service.send(:module_type_from_path, path)).to eq(module_type)
        end
      end
    end
  end
end
