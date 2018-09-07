require 'fast_spec_helper'

describe Gitlab::Ci::ExternalFiles::Mapper do
  let(:project) { create(:project, :repository) }

  describe '#process' do
    subject { described_class.new(values, project).process }

    context "when 'include' keyword is defined as string" do
      let(:values) do
        {
          include: '/vendor/gitlab-ci-yml/non-existent-file.yml',
          image: 'ruby:2.2'
        }
      end

      it 'returns an array' do
        expect(subject).to be_an(Array)
      end

      it 'returns ExternalFile instances' do
        expect(subject.first).to be_an_instance_of(::Gitlab::Ci::ExternalFiles::ExternalFile)
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

      it 'returns an array' do
        expect(subject).to be_an(Array)
      end

      it 'returns ExternalFile instances' do
        expect(subject).to all(be_an_instance_of(::Gitlab::Ci::ExternalFiles::ExternalFile))
      end
    end

    context "when 'include' is not defined" do
      let(:values) do
        { image: 'ruby:2.2' }
      end

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end
  end
end
