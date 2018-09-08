require 'spec_helper'

describe Gitlab::Ci::External::Processor do
  let(:project) { create(:project, :repository) }
  let(:processor) { described_class.new(values, project, '12345') }

  describe "#perform" do
    context 'when no external files defined' do
      let(:values) { { image: 'ruby:2.2' } }

      it 'should return the same values' do
        expect(processor.perform).to eq(values)
      end
    end

    context 'when an invalid local file is defined' do
      let(:values) { { include: '/vendor/gitlab-ci-yml/non-existent-file.yml', image: 'ruby:2.2' } }

      it 'should raise an error' do
        expect { processor.perform }.to raise_error(
          described_class::FileError,
          "Local file '/vendor/gitlab-ci-yml/non-existent-file.yml' is not valid."
        )
      end
    end

    context 'when an invalid remote file is defined' do
      let(:remote_file) { 'http://doesntexist.com/.gitlab-ci-1.yml' }
      let(:values) { { include: remote_file, image: 'ruby:2.2' } }

      before do
        WebMock.stub_request(:get, remote_file).to_raise(SocketError.new('Some HTTP error'))
      end

      it 'should raise an error' do
        expect { processor.perform }.to raise_error(
          described_class::FileError,
          "Remote file '#{remote_file}' is not valid."
        )
      end
    end

    context 'with a valid remote external file is defined' do
      let(:remote_file) { 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }
      let(:values) { { include: remote_file, image: 'ruby:2.2' } }
      let(:external_file_content) do
        <<-HEREDOC
        before_script:
          - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
          - ruby -v
          - which ruby
          - gem install bundler --no-ri --no-rdoc
          - bundle install --jobs $(nproc)  "${FLAGS[@]}"

        rspec:
          script:
            - bundle exec rspec

        rubocop:
          script:
            - bundle exec rubocop
        HEREDOC
      end

      before do
        WebMock.stub_request(:get, remote_file).to_return(body: external_file_content)
      end

      it 'should append the file to the values' do
        output = processor.perform
        expect(output.keys).to match_array([:image, :before_script, :rspec, :rubocop])
      end

      it "should remove the 'include' keyword" do
        expect(processor.perform[:include]).to be_nil
      end
    end

    context 'with a valid local external file is defined' do
      let(:values) { { include: '/vendor/gitlab-ci-yml/template.yml', image: 'ruby:2.2' } }
      let(:local_file_content) do
        <<-HEREDOC
        before_script:
          - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
          - ruby -v
          - which ruby
          - gem install bundler --no-ri --no-rdoc
          - bundle install --jobs $(nproc)  "${FLAGS[@]}"
        HEREDOC
      end

      before do
        allow_any_instance_of(Gitlab::Ci::External::File::Local).to receive(:fetch_local_content).and_return(local_file_content)
      end

      it 'should append the file to the values' do
        output = processor.perform
        expect(output.keys).to match_array([:image, :before_script])
      end

      it "should remove the 'include' keyword" do
        expect(processor.perform[:include]).to be_nil
      end
    end

    context 'with multiple external files are defined' do
      let(:remote_file) { 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }
      let(:external_files) do
        [
          '/ee/spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml',
          remote_file
        ]
      end
      let(:values) do
        {
          include: external_files,
          image: 'ruby:2.2'
        }
      end

      let(:remote_file_content) do
        <<-HEREDOC
        stages:
          - build
          - review
          - cleanup
        HEREDOC
      end

      before do
        local_file_content = File.read(Rails.root.join('ee/spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml'))
        allow_any_instance_of(Gitlab::Ci::External::File::Local).to receive(:fetch_local_content).and_return(local_file_content)
        WebMock.stub_request(:get, remote_file).to_return(body: remote_file_content)
      end

      it 'should append the files to the values' do
        expect(processor.perform.keys).to match_array([:image, :stages, :before_script, :rspec])
      end

      it "should remove the 'include' keyword" do
        expect(processor.perform[:include]).to be_nil
      end
    end

    context 'when external files are defined but not valid' do
      let(:values) { { include: '/vendor/gitlab-ci-yml/template.yml', image: 'ruby:2.2' } }

      let(:local_file_content) { 'invalid content file ////' }

      before do
        allow_any_instance_of(Gitlab::Ci::External::File::Local).to receive(:fetch_local_content).and_return(local_file_content)
      end

      it 'should raise an error' do
        expect { processor.perform }.to raise_error(Gitlab::Ci::Config::Loader::FormatError)
      end
    end

    context "when both external files and values defined the same key" do
      let(:remote_file) { 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }
      let(:values) do
        {
          include: remote_file,
          image: 'ruby:2.2'
        }
      end

      let(:remote_file_content) do
        <<~HEREDOC
        image: php:5-fpm-alpine
        HEREDOC
      end

      it 'should take precedence' do
        WebMock.stub_request(:get, remote_file).to_return(body: remote_file_content)
        expect(processor.perform[:image]).to eq('ruby:2.2')
      end
    end
  end
end
