require 'rails_helper'

describe Gitlab::Ci::ExternalFiles::Processor do
  let(:processor) { described_class.new(values) }

  describe "#perform" do
    context 'when no external files defined' do
      let(:values) { { image: 'ruby:2.2' } }

      it 'should return the same values' do
        expect(processor.perform).to eq(values)
      end
    end

    context 'when an invalid local file is defined' do
      let(:values) { { includes: '/vendor/gitlab-ci-yml/non-existent-file.yml', image: 'ruby:2.2'} }

      it 'should raise an error' do
        expect { processor.perform }.to raise_error(described_class::ExternalFileError)
      end
    end

    context 'when an invalid remote file is defined' do
      let(:values) { { includes: 'not-valid://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml', image: 'ruby:2.2'} }

      it 'should raise an error' do
        expect { processor.perform }.to raise_error(described_class::ExternalFileError)
      end
    end

    context 'with a valid remote external file is defined' do
      let(:values) { { includes: 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml', image: 'ruby:2.2' } }
      let(:external_file_content) {
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
      }

      before do
        allow_any_instance_of(Kernel).to receive_message_chain(:open, :read).and_return(external_file_content)
      end

      it 'should append the file to the values' do
        output = processor.perform
        expect(output.keys).to match_array([:image, :before_script, :rspec, :rubocop]) 
      end

      it "should remove the 'includes' keyword" do
        expect(processor.perform[:includes]).to be_nil
      end
    end

    context 'with a valid local external file is defined' do
      let(:values) { { includes: '/vendor/gitlab-ci-yml/template.yml' , image: 'ruby:2.2'} }
      let(:external_file_content) {
        <<-HEREDOC
        before_script:
          - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
          - ruby -v
          - which ruby
          - gem install bundler --no-ri --no-rdoc
          - bundle install --jobs $(nproc)  "${FLAGS[@]}"
        HEREDOC
      }

      before do
        allow(File).to receive(:exists?).and_return(true)
        allow(File).to receive(:read).and_return(external_file_content)
      end

      it 'should append the file to the values' do
        output = processor.perform
        expect(output.keys).to match_array([:image, :before_script]) 
      end

      it "should remove the 'includes' keyword" do
        expect(processor.perform[:includes]).to be_nil
      end
    end

    context 'with multiple external files are defined' do
      let(:external_files) { 
        [
          "/spec/ee/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml",
          "/spec/ee/fixtures/gitlab/ci/external_files/.gitlab-ci-template-2.yml",
          'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml'
        ]
      }
      let(:values) { { includes: external_files, image: 'ruby:2.2'} }

      let(:remote_file_content) {
        <<-HEREDOC
        stages:
          - build
          - review
          - cleanup
        HEREDOC
      }

      before do
        allow_any_instance_of(Kernel).to receive_message_chain(:open, :read).and_return(remote_file_content)
      end

      it 'should append the files to the values' do
        expect(processor.perform.keys).to match_array([:image, :variables, :stages, :before_script, :rspec])
      end

      it "should remove the 'includes' keyword" do
        expect(processor.perform[:includes]).to be_nil
      end
    end

    context 'when external files are defined but not valid' do
      let(:values) { { includes: '/vendor/gitlab-ci-yml/template.yml', image: 'ruby:2.2'} }

      let(:external_file_content) { 'invalid content file ////' }

      before do
        allow(File).to receive(:exists?).and_return(true)
        allow(File).to receive(:read).and_return(external_file_content)
      end

      it 'should raise an error' do
        expect { processor.perform }.to raise_error(Gitlab::Ci::Config::Loader::FormatError)
      end
    end
  end
end
