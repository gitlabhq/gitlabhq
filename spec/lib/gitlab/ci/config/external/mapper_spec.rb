# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Mapper do
  include StubRequests

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:local_file) { '/lib/gitlab/ci/templates/non-existent-file.yml' }
  let(:remote_url) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }
  let(:template_file) { 'Auto-DevOps.gitlab-ci.yml' }
  let(:context_params) { { project: project, sha: '123456', user: user, variables: project.predefined_variables.to_runner_variables } }
  let(:context) { Gitlab::Ci::Config::External::Context.new(**context_params) }

  let(:file_content) do
    <<~HEREDOC
    image: 'ruby:2.7'
    HEREDOC
  end

  before do
    stub_full_request(remote_url).to_return(body: file_content)

    allow_next_instance_of(Gitlab::Ci::Config::External::Context) do |instance|
      allow(instance).to receive(:check_execution_time!)
    end
  end

  describe '#process' do
    subject { described_class.new(values, context).process }

    context "when single 'include' keyword is defined" do
      context 'when the string is a local file' do
        let(:values) do
          { include: local_file,
            image: 'ruby:2.7' }
        end

        it 'returns File instances' do
          expect(subject).to contain_exactly(
            an_instance_of(Gitlab::Ci::Config::External::File::Local))
        end
      end

      context 'when the key is a local file hash' do
        let(:values) do
          { include: { 'local' => local_file },
            image: 'ruby:2.7' }
        end

        it 'returns File instances' do
          expect(subject).to contain_exactly(
            an_instance_of(Gitlab::Ci::Config::External::File::Local))
        end
      end

      context 'when the string is a remote file' do
        let(:values) do
          { include: remote_url, image: 'ruby:2.7' }
        end

        it 'returns File instances' do
          expect(subject).to contain_exactly(
            an_instance_of(Gitlab::Ci::Config::External::File::Remote))
        end
      end

      context 'when the key is a remote file hash' do
        let(:values) do
          { include: { 'remote' => remote_url },
            image: 'ruby:2.7' }
        end

        it 'returns File instances' do
          expect(subject).to contain_exactly(
            an_instance_of(Gitlab::Ci::Config::External::File::Remote))
        end
      end

      context 'when the key is a template file hash' do
        let(:values) do
          { include: { 'template' => template_file },
            image: 'ruby:2.7' }
        end

        it 'returns File instances' do
          expect(subject).to contain_exactly(
            an_instance_of(Gitlab::Ci::Config::External::File::Template))
        end
      end

      context 'when the key is a hash of file and remote' do
        let(:values) do
          { include: { 'local' => local_file, 'remote' => remote_url },
            image: 'ruby:2.7' }
        end

        it 'returns ambigious specification error' do
          expect { subject }.to raise_error(described_class::AmbigiousSpecificationError)
        end
      end

      context "when the key is a project's file" do
        let(:values) do
          { include: { project: project.full_path, file: local_file },
            image: 'ruby:2.7' }
        end

        it 'returns File instances' do
          expect(subject).to contain_exactly(
            an_instance_of(Gitlab::Ci::Config::External::File::Project))
        end
      end

      context "when the key is project's files" do
        let(:values) do
          { include: { project: project.full_path, file: [local_file, 'another_file_path.yml'] },
            image: 'ruby:2.7' }
        end

        it 'returns two File instances' do
          expect(subject).to contain_exactly(
            an_instance_of(Gitlab::Ci::Config::External::File::Project),
            an_instance_of(Gitlab::Ci::Config::External::File::Project))
        end
      end
    end

    context "when 'include' is defined as an array" do
      let(:values) do
        { include: [remote_url, local_file],
          image: 'ruby:2.7' }
      end

      it 'returns Files instances' do
        expect(subject).to all(respond_to(:valid?))
        expect(subject).to all(respond_to(:content))
      end
    end

    context "when 'include' is defined as an array of hashes" do
      let(:values) do
        { include: [{ remote: remote_url }, { local: local_file }],
          image: 'ruby:2.7' }
      end

      it 'returns Files instances' do
        expect(subject).to all(respond_to(:valid?))
        expect(subject).to all(respond_to(:content))
      end

      context 'when it has ambigious match' do
        let(:values) do
          { include: [{ remote: remote_url, local: local_file }],
            image: 'ruby:2.7' }
        end

        it 'returns ambigious specification error' do
          expect { subject }.to raise_error(described_class::AmbigiousSpecificationError)
        end
      end
    end

    context "when 'include' is not defined" do
      let(:values) do
        {
          image: 'ruby:2.7'
        }
      end

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end

    context "when duplicate 'include' is defined" do
      let(:values) do
        { include: [
            { 'local' => local_file },
            { 'local' => local_file }
          ],
          image: 'ruby:2.7' }
      end

      it 'raises an exception' do
        expect { subject }.to raise_error(described_class::DuplicateIncludesError)
      end

      context 'when including multiple files from a project' do
        let(:values) do
          { include: { project: project.full_path, file: [local_file, local_file] } }
        end

        it 'raises an exception' do
          expect { subject }.to raise_error(described_class::DuplicateIncludesError)
        end
      end
    end

    context "when too many 'includes' are defined" do
      let(:values) do
        { include: [
            { 'local' => local_file },
            { 'remote' => remote_url }
          ],
          image: 'ruby:2.7' }
      end

      before do
        stub_const("#{described_class}::MAX_INCLUDES", 1)
      end

      it 'raises an exception' do
        expect { subject }.to raise_error(described_class::TooManyIncludesError)
      end

      context 'when including multiple files from a project' do
        let(:values) do
          { include: { project: project.full_path, file: [local_file, 'another_file_path.yml'] } }
        end

        it 'raises an exception' do
          expect { subject }.to raise_error(described_class::TooManyIncludesError)
        end
      end
    end

    context "when 'include' section uses project variable" do
      let(:full_local_file_path) { '$CI_PROJECT_PATH' + local_file }

      context 'when local file is included as a single string' do
        let(:values) do
          { include: full_local_file_path }
        end

        it 'expands the variable', :aggregate_failures do
          expect(subject[0].location).to eq(project.full_path + local_file)
          expect(subject).to contain_exactly(an_instance_of(Gitlab::Ci::Config::External::File::Local))
        end
      end

      context 'when remote file is included as a single string' do
        let(:remote_url) { "#{Gitlab.config.gitlab.url}/radio/.gitlab-ci.yml" }

        let(:values) do
          { include: '$CI_SERVER_URL/radio/.gitlab-ci.yml' }
        end

        it 'expands the variable', :aggregate_failures do
          expect(subject[0].location).to eq(remote_url)
          expect(subject).to contain_exactly(an_instance_of(Gitlab::Ci::Config::External::File::Remote))
        end
      end

      context 'defined as an array' do
        let(:values) do
          { include: [full_local_file_path, remote_url],
            image: 'ruby:2.7' }
        end

        it 'expands the variable' do
          expect(subject[0].location).to eq(project.full_path + local_file)
          expect(subject[1].location).to eq(remote_url)
        end
      end

      context 'defined as an array of hashes' do
        let(:values) do
          { include: [{ local: full_local_file_path }, { remote: remote_url }],
            image: 'ruby:2.7' }
        end

        it 'expands the variable' do
          expect(subject[0].location).to eq(project.full_path + local_file)
          expect(subject[1].location).to eq(remote_url)
        end
      end

      context 'local file hash' do
        let(:values) do
          { include: { 'local' => full_local_file_path } }
        end

        it 'expands the variable' do
          expect(subject[0].location).to eq(project.full_path + local_file)
        end
      end

      context 'project name' do
        let(:values) do
          { include: { project: '$CI_PROJECT_PATH', file: local_file },
            image: 'ruby:2.7' }
        end

        it 'expands the variable', :aggregate_failures do
          expect(subject[0].project_name).to eq(project.full_path)
          expect(subject).to contain_exactly(an_instance_of(Gitlab::Ci::Config::External::File::Project))
        end
      end

      context 'with multiple files' do
        let(:values) do
          { include: { project: project.full_path, file: [full_local_file_path, 'another_file_path.yml'] },
            image: 'ruby:2.7' }
        end

        it 'expands the variable' do
          expect(subject[0].location).to eq(project.full_path + local_file)
          expect(subject[1].location).to eq('another_file_path.yml')
        end
      end

      context 'when include variable has an unsupported type for variable expansion' do
        let(:values) do
          { include: { project: project.id, file: local_file },
            image: 'ruby:2.7' }
        end

        it 'does not invoke expansion for the variable', :aggregate_failures do
          expect(ExpandVariables).not_to receive(:expand).with(project.id, context_params[:variables])

          expect { subject }.to raise_error(described_class::AmbigiousSpecificationError)
        end
      end
    end

    context 'when local file path has wildcard' do
      let(:project) { create(:project, :repository) }

      let(:values) do
        { include: 'myfolder/*.yml' }
      end

      before do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:search_files_by_wildcard_path).with('myfolder/*.yml', '123456') do
            ['myfolder/file1.yml', 'myfolder/file2.yml']
          end
        end
      end

      it 'includes the matched local files' do
        expect(subject).to contain_exactly(an_instance_of(Gitlab::Ci::Config::External::File::Local),
                                           an_instance_of(Gitlab::Ci::Config::External::File::Local))

        expect(subject.map(&:location)).to contain_exactly('myfolder/file1.yml', 'myfolder/file2.yml')
      end

      context 'when the FF ci_wildcard_file_paths is disabled' do
        before do
          stub_feature_flags(ci_wildcard_file_paths: false)
        end

        it 'cannot find any file returns an error message' do
          expect(subject).to contain_exactly(an_instance_of(Gitlab::Ci::Config::External::File::Local))
          expect(subject[0].errors).to eq(['Local file `myfolder/*.yml` does not exist!'])
        end
      end
    end
  end
end
