require 'rails_helper'

describe Gitlab::Ci::ExternalFiles::Processor do
  let(:project) { create(:project, :repository) }
  let(:processor) { described_class.new(values, project) }

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
          described_class::ExternalFileError,
          "External file: '/vendor/gitlab-ci-yml/non-existent-file.yml' should be a valid local or remote file"
        )
      end
    end

    context 'when an invalid remote file is defined' do
      let(:values) { { include: 'not-valid://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml', image: 'ruby:2.2' } }

      it 'should raise an error' do
        expect { processor.perform }.to raise_error(
          described_class::ExternalFileError,
          "External file: 'not-valid://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' should be a valid local or remote file"
        )
      end
    end

    context 'with a valid remote external file is defined' do
      let(:values) { { include: 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml', image: 'ruby:2.2' } }
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
        allow(HTTParty).to receive(:get).and_return(external_file_content)
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
      let(:external_file_content) do
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
        allow_any_instance_of(::Gitlab::Ci::ExternalFiles::ExternalFile).to receive(:local_file_content).and_return(external_file_content)
      end

      it 'should append the file to the values' do
        output = processor.perform
        expect(output.keys).to match_array([:image, :before_script])
      end

      it "should remove the 'include' keyword" do
        expect(processor.perform[:includes]).to be_nil
      end
    end

    context 'with multiple external files are defined' do
      let(:external_files) do
        [
          "/spec/ee/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml",
          'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml'
        ]
      end
      let(:values) { { include: external_files, image: 'ruby:2.2' } }

      let(:remote_file_content) do
        <<-HEREDOC
        stages:
          - build
          - review
          - cleanup
        HEREDOC
      end

      before do
        file_content = File.read("#{Rails.root}/spec/ee/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml")
        allow_any_instance_of(::Gitlab::Ci::ExternalFiles::ExternalFile).to receive(:local_file_content).and_return(file_content)
        allow(HTTParty).to receive(:get).and_return(remote_file_content)
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

      let(:external_file_content) { 'invalid content file ////' }

      before do
        allow_any_instance_of(::Gitlab::Ci::ExternalFiles::ExternalFile).to receive(:local_file_content).and_return(external_file_content)
      end

      it 'should raise an error' do
        expect { processor.perform }.to raise_error(Gitlab::Ci::Config::Loader::FormatError)
      end
    end
  end
end
