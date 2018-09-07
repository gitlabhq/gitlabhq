require 'fast_spec_helper'

describe Gitlab::Ci::External::Mapper do
  let(:project) { create(:project, :repository) }
  let(:file_content) do
    <<~HEREDOC
    image: 'ruby:2.2'
    HEREDOC
  end

  describe '#process' do
    subject { described_class.new(values, project, 'testing').process }

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
          expect(subject.first).to be_an_instance_of(::Gitlab::Ci::External::File::Local)
        end
      end

      context 'when the string is a remote file' do
        let(:values) do
          {
            include: 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml',
            image: 'ruby:2.2'
          }
        end

        before do
          allow(HTTParty).to receive(:get).and_return(file_content)
        end

        it 'returns an array' do
          expect(subject).to be_an(Array)
        end

        it 'returns File instances' do
          expect(subject.first).to be_an_instance_of(::Gitlab::Ci::External::File::Remote)
        end
      end
    end

    context "when 'include' is defined as an array" do
      let(:values) do
        {
          include:
          [
            'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml',
            '/vendor/gitlab-ci-yml/template.yml'
          ],
          image: 'ruby:2.2'
        }
      end

      before do
        allow(HTTParty).to receive(:get).and_return(file_content)
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
