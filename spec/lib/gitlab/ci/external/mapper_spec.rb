# frozen_string_literal: true

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
            include: '/lib/gitlab/ci/templates/non-existent-file.yml',
            image: 'ruby:2.2'
          }
        end

        it 'returns an array' do
          expect(subject).to be_an(Array)
        end

        it 'returns File::Local instances' do
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

        it 'returns an array' do
          expect(subject).to be_an(Array)
        end

        it 'returns File instances' do
          expect(subject.first).to be_an_instance_of(Gitlab::Ci::External::File::Remote)
        end
      end
    end

    context 'when include is a hash' do
      context 'when ignore_if_missing is true' do
        context 'when using a local file' do
          let(:values) do
            {
              include: {
                path: '/path1',
                ignore_if_missing: true
              }
            }
          end

          it 'returns expected File::Local instances' do
            expect(subject.first).to be_an_instance_of(Gitlab::Ci::External::File::Local)
            expect(subject.first.ignore_if_missing).to eq(true)
          end
        end

        context 'when using a remote file' do
          let(:values) do
            {
              include: {
                path: 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1235/.gitlab-ci-1.yml',
                ignore_if_missing: true
              }
            }
          end

          it 'should raise IncludeError' do
            expect { subject }
              .to raise_error(
                Gitlab::Ci::External::Mapper::IncludeError,
                'ignore_if_missing must be false or not included for remote files'
            )
          end
        end

        context 'when using a local file' do
          let(:values) do
            {
              include: '',
            }
          end
        end
      end
    end

    context 'when include is an array of hashes' do
      let(:values) do
        {
          include: [
            {
              path: '/path1',
              ignore_if_missing: true
            },
            {
              path: '/path2',
              ignore_if_missing: false
            },
            {
              path: '/path3'
            }
          ]
        }
      end

      it 'returns expected File::Local instances' do
        expect(subject[0]).to be_an_instance_of(Gitlab::Ci::External::File::Local)
        expect(subject[0].location).to eq('/path1')
        expect(subject[0].ignore_if_missing).to eq(true)

        expect(subject[1]).to be_an_instance_of(Gitlab::Ci::External::File::Local)
        expect(subject[1].location).to eq('/path2')
        expect(subject[1].ignore_if_missing).to eq(false)

        expect(subject[2]).to be_an_instance_of(Gitlab::Ci::External::File::Local)
        expect(subject[2].location).to eq('/path3')
        expect(subject[2].ignore_if_missing).to eq(false)
      end
    end

    context "when 'include' is defined as an array" do
      let(:remote_url) { 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }
      let(:values) do
        {
          include:
          [
            remote_url,
            '/lib/gitlab/ci/templates/template.yml'
          ],
          image: 'ruby:2.2'
        }
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
