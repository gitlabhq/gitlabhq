require 'spec_helper'

describe HasStatus do
  describe '.status' do
    subject { CommitStatus.status }

    shared_examples 'build status summary' do
      context 'all successful' do
        let!(:statuses) { Array.new(2) { create(type, status: :success) } }
        it { is_expected.to eq 'success' }
      end

      context 'at least one failed' do
        let!(:statuses) do
          [create(type, status: :success), create(type, status: :failed)]
        end

        it { is_expected.to eq 'failed' }
      end

      context 'at least one running' do
        let!(:statuses) do
          [create(type, status: :success), create(type, status: :running)]
        end

        it { is_expected.to eq 'running' }
      end

      context 'at least one pending' do
        let!(:statuses) do
          [create(type, status: :success), create(type, status: :pending)]
        end

        it { is_expected.to eq 'running' }
      end

      context 'success and failed but allowed to fail' do
        let!(:statuses) do
          [create(type, status: :success),
           create(type, status: :failed, allow_failure: true)]
        end

        it { is_expected.to eq 'success' }
      end

      context 'one failed but allowed to fail' do
        let!(:statuses) do
          [create(type, status: :failed, allow_failure: true)]
        end

        it { is_expected.to eq 'success' }
      end

      context 'success and canceled' do
        let!(:statuses) do
          [create(type, status: :success), create(type, status: :canceled)]
        end

        it { is_expected.to eq 'canceled' }
      end

      context 'one failed and one canceled' do
        let!(:statuses) do
          [create(type, status: :failed), create(type, status: :canceled)]
        end

        it { is_expected.to eq 'failed' }
      end

      context 'one failed but allowed to fail and one canceled' do
        let!(:statuses) do
          [create(type, status: :failed, allow_failure: true),
           create(type, status: :canceled)]
        end

        it { is_expected.to eq 'canceled' }
      end

      context 'one running one canceled' do
        let!(:statuses) do
          [create(type, status: :running), create(type, status: :canceled)]
        end

        it { is_expected.to eq 'running' }
      end

      context 'all canceled' do
        let!(:statuses) do
          [create(type, status: :canceled), create(type, status: :canceled)]
        end

        it { is_expected.to eq 'canceled' }
      end

      context 'success and canceled but allowed to fail' do
        let!(:statuses) do
          [create(type, status: :success),
           create(type, status: :canceled, allow_failure: true)]
        end

        it { is_expected.to eq 'success' }
      end

      context 'one finished and second running but allowed to fail' do
        let!(:statuses) do
          [create(type, status: :success),
           create(type, status: :running, allow_failure: true)]
        end

        it { is_expected.to eq 'running' }
      end
    end

    context 'ci build statuses' do
      let(:type) { :ci_build }

      it_behaves_like 'build status summary'
    end

    context 'generic commit statuses' do
      let(:type) { :generic_commit_status }

      it_behaves_like 'build status summary'
    end
  end

  def self.random_type
    %i[ci_build generic_commit_status].sample
  end

  context 'for scope with one status' do
    shared_examples 'having a job' do |type, status|
      context "when it's #{status} #{type} job" do
        let!(:job) { create(type, status) }

        describe ".#{status}" do
          subject { CommitStatus.public_send(status).all }

          it { is_expected.to contain_exactly(job) }
        end

        describe '.relevant' do
          subject { CommitStatus.relevant.all }

          it do
            case status
            when :created
              is_expected.to be_empty
            else
              is_expected.to contain_exactly(job)
            end
          end
        end
      end
    end

    %i[created running pending success
       failed canceled skipped].each do |status|
      it_behaves_like 'having a job', random_type, status
    end
  end

  context 'for scope with more statuses' do
    shared_examples 'having a job' do |type, status, excluded_status|
      context "when it's #{status} #{type} job" do
        let!(:job) { create(type, status) }

        it do
          case status
          when excluded_status
            is_expected.to be_empty
          else
            is_expected.to contain_exactly(job)
          end
        end
      end
    end

    describe '.running_or_pending' do
      subject { CommitStatus.running_or_pending }

      %i[running pending created].each do |status|
        it_behaves_like 'having a job', random_type, status, :created
      end
    end

    describe '.finished' do
      subject { CommitStatus.finished }

      %i[success failed canceled created].each do |status|
        it_behaves_like 'having a job', random_type, status, :created
      end
    end

    describe '.cancelable' do
      subject { CommitStatus.cancelable }

      %i[running pending created failed].each do |status|
        it_behaves_like 'having a job', random_type, status, :failed
      end
    end
  end
end
