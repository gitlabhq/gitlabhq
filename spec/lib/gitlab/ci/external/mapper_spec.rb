require 'spec_helper'

describe Gitlab::Ci::External::Mapper do
  let(:project) { create(:project, :repository) }
  let(:file_content) do
    <<~HEREDOC
    image: 'ruby:2.2'
    HEREDOC
  end

  describe '#process' do
    subject { described_class.new(values, project, '123456').process }

    context "when 'include' keyword is defined as string" do
      context 'when the string is a local file' do
        let(:values) do
          {
            include: '/vendor/gitlab-ci-yml/non-existent-file.yml',
            image: 'ruby:2.2'
          }
        end

        it 'returns an array' do
          expect(subject).to be_an(Array)
        end

        it 'returns File instances' do
          expect(subject.first).to be_an_instance_of(Gitlab::Ci::External::File::Local)
        end
      end

      context 'when the string is a remote file' do
        let(:remote_url) { 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }
        let(:values) do
          {
            include: remote_url,
            image: 'ruby:2.2'
          }
        end

        before do
          WebMock.stub_request(:get, remote_url).to_return(body: file_content)
        end

        it 'returns an array' do
          expect(subject).to be_an(Array)
        end

        it 'returns File instances' do
          expect(subject.first).to be_an_instance_of(Gitlab::Ci::External::File::Remote)
        end
      end
    end

    context "when 'include' is defined as an array" do
      let(:remote_url) { 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }
      let(:values) do
        {
          include:
          [
            remote_url,
            '/vendor/gitlab-ci-yml/template.yml'
          ],
          image: 'ruby:2.2'
        }
      end

      before do
        WebMock.stub_request(:get, remote_url).to_return(body: file_content)
      end

      it 'returns an array' do
        expect(subject).to be_an(Array)
      end

      it 'returns Files instances' do
        expect(subject).to all(respond_to(:valid?))
        expect(subject).to all(respond_to(:content))
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
  end
end
