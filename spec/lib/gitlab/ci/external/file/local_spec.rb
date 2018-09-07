require 'fast_spec_helper'

describe Gitlab::Ci::External::File::Local do
  let(:project) { create(:project, :repository) }
  let(:local_file) { described_class.new(location, { project: project, sha: '12345' }) }

  describe "#valid?" do
    context 'when is a valid local path' do
      let(:location) { '/vendor/gitlab-ci-yml/existent-file.yml' }

      before do
        allow_any_instance_of(described_class).to receive(:local_file_content).and_return("image: 'ruby2:2'")
      end

      it 'should return true' do
        expect(local_file.valid?).to be_truthy
      end
    end

    context 'when is not a valid local path' do
      let(:location) { '/vendor/gitlab-ci-yml/non-existent-file.yml' }

      it 'should return false' do
        expect(local_file.valid?).to be_falsy
      end
    end

    describe "#content" do
      let(:local_file_content) do
        <<~HEREDOC
      before_script:
        - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
        - ruby -v
        - which ruby
        - gem install bundler --no-ri --no-rdoc
        - bundle install --jobs $(nproc)  "${FLAGS[@]}"
        HEREDOC
      end

      context 'with a local file' do
        let(:location) { '/vendor/gitlab-ci-yml/non-existent-file.yml' }

        before do
          allow_any_instance_of(described_class).to receive(:local_file_content).and_return(local_file_content)
        end

        it 'should return the content of the file' do
          expect(local_file.content).to eq(local_file_content)
        end
      end
    end
  end
end
