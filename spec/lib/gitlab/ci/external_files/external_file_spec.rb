require 'rails_helper'

describe Gitlab::Ci::ExternalFiles::ExternalFile do
  let(:external_file) { described_class.new(value) }

  describe "#valid?" do
    context 'when is a valid remote url' do
      let(:value) { 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }

      it 'should return true' do
        expect(external_file.valid?).to be_truthy
      end
    end

    context 'when is not a valid remote url' do
       let(:value) { 'not-valid://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }

      it 'should return false' do
        expect(external_file.valid?).to be_falsy
      end
    end

    context 'when is a valid local path' do
      let(:value) { '/vendor/gitlab-ci-yml/existent-file.yml' }

      it 'should return true' do
        allow(File).to receive(:exists?).and_return(true)
        expect(external_file.valid?).to be_truthy
      end
    end

    context 'when is not a valid local path' do
      let(:value) { '/vendor/gitlab-ci-yml/non-existent-file.yml' }

      it 'should return false' do
        expect(external_file.valid?).to be_falsy
      end
    end
  end

  describe "#content" do
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

    context 'with a local file' do
      let(:value) { '/vendor/gitlab-ci-yml/non-existent-file.yml' }

      before do
        allow(File).to receive(:exists?).and_return(true)
        allow(File).to receive(:read).and_return(external_file_content)
      end

      it 'should return the content of the file' do
        expect(external_file.content).to eq(external_file_content)
      end
    end

    context 'with a valid remote file' do
      let(:value) { 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }

      before do
        allow_any_instance_of(Kernel).to receive_message_chain(:open, :read).and_return(external_file_content)
      end

      it 'should return the content of the file' do
        expect(external_file.content).to eq(external_file_content)
      end
    end
  end
end
