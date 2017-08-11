require 'spec_helper'

describe RspecFlaky::FlakyExample do
  let(:flaky_example_attrs) do
    {
      example_id: 'spec/foo/bar_spec.rb:2',
      file: 'spec/foo/bar_spec.rb',
      line: 2,
      description: 'hello world',
      first_flaky_at: 1234,
      last_flaky_at: 2345,
      last_attempts_count: 2,
      flaky_reports: 1
    }
  end
  let(:example_attrs) do
    {
      uid: 'abc123',
      example_id: flaky_example_attrs[:example_id],
      file: flaky_example_attrs[:file],
      line: flaky_example_attrs[:line],
      description: flaky_example_attrs[:description],
      status: 'passed',
      exception: 'BOOM!',
      attempts: flaky_example_attrs[:last_attempts_count]
    }
  end
  let(:example) { double(example_attrs) }

  describe '#initialize' do
    shared_examples 'a valid FlakyExample instance' do
      it 'returns valid attributes' do
        flaky_example = described_class.new(args)

        expect(flaky_example.uid).to eq(flaky_example_attrs[:uid])
        expect(flaky_example.example_id).to eq(flaky_example_attrs[:example_id])
      end
    end

    context 'when given an Rspec::Example' do
      let(:args) { example }

      it_behaves_like 'a valid FlakyExample instance'
    end

    context 'when given a hash' do
      let(:args) { flaky_example_attrs }

      it_behaves_like 'a valid FlakyExample instance'
    end
  end

  describe '#to_h' do
    before do
      # Stub these env variables otherwise specs don't behave the same on the CI
      stub_env('CI_PROJECT_URL', nil)
      stub_env('CI_JOB_ID', nil)
    end

    shared_examples 'a valid FlakyExample hash' do
      let(:additional_attrs) { {} }

      it 'returns a valid hash' do
        flaky_example = described_class.new(args)
        final_hash = flaky_example_attrs
          .merge(last_flaky_at: instance_of(Time), last_flaky_job: nil)
          .merge(additional_attrs)

        expect(flaky_example.to_h).to match(hash_including(final_hash))
      end
    end

    context 'when given an Rspec::Example' do
      let(:args) { example }

      context 'when run locally' do
        it_behaves_like 'a valid FlakyExample hash' do
          let(:additional_attrs) do
            { first_flaky_at: instance_of(Time) }
          end
        end
      end

      context 'when run on the CI' do
        before do
          stub_env('CI_PROJECT_URL', 'https://gitlab.com/gitlab-org/gitlab-ce')
          stub_env('CI_JOB_ID', 42)
        end

        it_behaves_like 'a valid FlakyExample hash' do
          let(:additional_attrs) do
            { first_flaky_at: instance_of(Time), last_flaky_job: "https://gitlab.com/gitlab-org/gitlab-ce/-/jobs/42" }
          end
        end
      end
    end

    context 'when given a hash' do
      let(:args) { flaky_example_attrs }

      it_behaves_like 'a valid FlakyExample hash'
    end
  end
end
