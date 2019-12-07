# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::External::Mapper do
  include StubRequests

  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }

  let(:local_file) { '/lib/gitlab/ci/templates/non-existent-file.yml' }
  let(:remote_url) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }
  let(:template_file) { 'Auto-DevOps.gitlab-ci.yml' }
  let(:context_params) { { project: project, sha: '123456', user: user } }
  let(:context) { Gitlab::Ci::Config::External::Context.new(**context_params) }

  let(:file_content) do
    <<~HEREDOC
    image: 'ruby:2.2'
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
            image: 'ruby:2.2' }
        end

        it 'returns File instances' do
          expect(subject).to contain_exactly(
            an_instance_of(Gitlab::Ci::Config::External::File::Local))
        end
      end

      context 'when the key is a local file hash' do
        let(:values) do
          { include: { 'local' => local_file },
            image: 'ruby:2.2' }
        end

        it 'returns File instances' do
          expect(subject).to contain_exactly(
            an_instance_of(Gitlab::Ci::Config::External::File::Local))
        end
      end

      context 'when the string is a remote file' do
        let(:values) do
          { include: remote_url, image: 'ruby:2.2' }
        end

        it 'returns File instances' do
          expect(subject).to contain_exactly(
            an_instance_of(Gitlab::Ci::Config::External::File::Remote))
        end
      end

      context 'when the key is a remote file hash' do
        let(:values) do
          { include: { 'remote' => remote_url },
            image: 'ruby:2.2' }
        end

        it 'returns File instances' do
          expect(subject).to contain_exactly(
            an_instance_of(Gitlab::Ci::Config::External::File::Remote))
        end
      end

      context 'when the key is a template file hash' do
        let(:values) do
          { include: { 'template' => template_file },
            image: 'ruby:2.2' }
        end

        it 'returns File instances' do
          expect(subject).to contain_exactly(
            an_instance_of(Gitlab::Ci::Config::External::File::Template))
        end
      end

      context 'when the key is a hash of file and remote' do
        let(:values) do
          { include: { 'local' => local_file, 'remote' => remote_url },
            image: 'ruby:2.2' }
        end

        it 'returns ambigious specification error' do
          expect { subject }.to raise_error(described_class::AmbigiousSpecificationError)
        end
      end
    end

    context "when 'include' is defined as an array" do
      let(:values) do
        { include: [remote_url, local_file],
          image: 'ruby:2.2' }
      end

      it 'returns Files instances' do
        expect(subject).to all(respond_to(:valid?))
        expect(subject).to all(respond_to(:content))
      end
    end

    context "when 'include' is defined as an array of hashes" do
      let(:values) do
        { include: [{ remote: remote_url }, { local: local_file }],
          image: 'ruby:2.2' }
      end

      it 'returns Files instances' do
        expect(subject).to all(respond_to(:valid?))
        expect(subject).to all(respond_to(:content))
      end

      context 'when it has ambigious match' do
        let(:values) do
          { include: [{ remote: remote_url, local: local_file }],
            image: 'ruby:2.2' }
        end

        it 'returns ambigious specification error' do
          expect { subject }.to raise_error(described_class::AmbigiousSpecificationError)
        end
      end
    end

    context "when 'include' is not defined" do
      let(:values) do
        {
          image: 'ruby:2.2'
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
          image: 'ruby:2.2' }
      end

      it 'raises an exception' do
        expect { subject }.to raise_error(described_class::DuplicateIncludesError)
      end
    end

    context "when too many 'includes' are defined" do
      let(:values) do
        { include: [
            { 'local' => local_file },
            { 'remote' => remote_url }
          ],
          image: 'ruby:2.2' }
      end

      before do
        stub_const("#{described_class}::MAX_INCLUDES", 1)
      end

      it 'raises an exception' do
        expect { subject }.to raise_error(described_class::TooManyIncludesError)
      end
    end
  end
end
