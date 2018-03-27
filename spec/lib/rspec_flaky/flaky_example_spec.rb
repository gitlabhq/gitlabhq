require 'spec_helper'

describe RspecFlaky::FlakyExample, :aggregate_failures do
  let(:flaky_example_attrs) do
    {
      example_id: 'spec/foo/bar_spec.rb:2',
      file: 'spec/foo/bar_spec.rb',
      line: 2,
      description: 'hello world',
      first_flaky_at: 1234,
      last_flaky_at: 2345,
      last_flaky_job: 'https://gitlab.com/gitlab-org/gitlab-ce/-/jobs/12',
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

  before do
    # Stub these env variables otherwise specs don't behave the same on the CI
    stub_env('CI_PROJECT_URL', nil)
    stub_env('CI_JOB_ID', nil)
  end

  describe '#initialize' do
    shared_examples 'a valid FlakyExample instance' do
      let(:flaky_example) { described_class.new(args) }

      it 'returns valid attributes' do
        expect(flaky_example.uid).to eq(flaky_example_attrs[:uid])
        expect(flaky_example.file).to eq(flaky_example_attrs[:file])
        expect(flaky_example.line).to eq(flaky_example_attrs[:line])
        expect(flaky_example.description).to eq(flaky_example_attrs[:description])
        expect(flaky_example.first_flaky_at).to eq(expected_first_flaky_at)
        expect(flaky_example.last_flaky_at).to eq(expected_last_flaky_at)
        expect(flaky_example.last_attempts_count).to eq(flaky_example_attrs[:last_attempts_count])
        expect(flaky_example.flaky_reports).to eq(expected_flaky_reports)
      end
    end

    context 'when given an Rspec::Example' do
      it_behaves_like 'a valid FlakyExample instance' do
        let(:args) { example }
        let(:expected_first_flaky_at) { nil }
        let(:expected_last_flaky_at) { nil }
        let(:expected_flaky_reports) { 0 }
      end
    end

    context 'when given a hash' do
      it_behaves_like 'a valid FlakyExample instance' do
        let(:args) { flaky_example_attrs }
        let(:expected_flaky_reports) { flaky_example_attrs[:flaky_reports] }
        let(:expected_first_flaky_at) { flaky_example_attrs[:first_flaky_at] }
        let(:expected_last_flaky_at) { flaky_example_attrs[:last_flaky_at] }
      end
    end
  end

  describe '#update_flakiness!' do
    shared_examples 'an up-to-date FlakyExample instance' do
      let(:flaky_example) { described_class.new(args) }

      it 'updates the first_flaky_at' do
        now = Time.now
        expected_first_flaky_at = flaky_example.first_flaky_at ? flaky_example.first_flaky_at : now
        Timecop.freeze(now) { flaky_example.update_flakiness! }

        expect(flaky_example.first_flaky_at).to eq(expected_first_flaky_at)
      end

      it 'updates the last_flaky_at' do
        now = Time.now
        Timecop.freeze(now) { flaky_example.update_flakiness! }

        expect(flaky_example.last_flaky_at).to eq(now)
      end

      it 'updates the flaky_reports' do
        expected_flaky_reports = flaky_example.first_flaky_at ? flaky_example.flaky_reports + 1 : 1

        expect { flaky_example.update_flakiness! }.to change { flaky_example.flaky_reports }.by(1)
        expect(flaky_example.flaky_reports).to eq(expected_flaky_reports)
      end

      context 'when passed a :last_attempts_count' do
        it 'updates the last_attempts_count' do
          flaky_example.update_flakiness!(last_attempts_count: 42)

          expect(flaky_example.last_attempts_count).to eq(42)
        end
      end

      context 'when run on the CI' do
        before do
          stub_env('CI_PROJECT_URL', 'https://gitlab.com/gitlab-org/gitlab-ce')
          stub_env('CI_JOB_ID', 42)
        end

        it 'updates the last_flaky_job' do
          flaky_example.update_flakiness!

          expect(flaky_example.last_flaky_job).to eq('https://gitlab.com/gitlab-org/gitlab-ce/-/jobs/42')
        end
      end
    end

    context 'when given an Rspec::Example' do
      it_behaves_like 'an up-to-date FlakyExample instance' do
        let(:args) { example }
      end
    end

    context 'when given a hash' do
      it_behaves_like 'an up-to-date FlakyExample instance' do
        let(:args) { flaky_example_attrs }
      end
    end
  end

  describe '#to_h' do
    shared_examples 'a valid FlakyExample hash' do
      let(:additional_attrs) { {} }

      it 'returns a valid hash' do
        flaky_example = described_class.new(args)
        final_hash = flaky_example_attrs.merge(additional_attrs)

        expect(flaky_example.to_h).to eq(final_hash)
      end
    end

    context 'when given an Rspec::Example' do
      let(:args) { example }

      it_behaves_like 'a valid FlakyExample hash' do
        let(:additional_attrs) do
          { first_flaky_at: nil, last_flaky_at: nil, last_flaky_job: nil, flaky_reports: 0 }
        end
      end
    end

    context 'when given a hash' do
      let(:args) { flaky_example_attrs }

      it_behaves_like 'a valid FlakyExample hash'
    end
  end
end
