# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::Asana do
  describe 'Validations' do
    context 'when active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of :api_key }
    end

    context 'when inactive' do
      it { is_expected.not_to validate_presence_of :api_key }
    end
  end

  # rubocop:disable RSpec/VerifiedDoubles -- legacy use
  describe '#execute' do
    let_it_be(:user) { build(:user) }
    let_it_be(:project) { build(:project) }

    let(:gid) { "123456789ABCD" }
    let(:asana_task) { double(data: { gid: gid }) }
    let(:asana_integration) { described_class.new }
    let(:ref) { 'main' }
    let(:restrict_to_branch) { nil }

    let(:data) do
      {
        object_kind: 'push',
        ref: ref,
        user_name: user.name,
        commits: [
          {
            message: message,
            url: 'https://gitlab.com/'
          }
        ]
      }
    end

    let(:completed_message) do
      {
        body: {
          completed: true
        },
        headers: { "Authorization" => "Bearer verySecret" }
      }
    end

    before do
      allow(asana_integration).to receive_messages(
        project: project,
        project_id: project.id,
        api_key: 'verySecret',
        restrict_to_branch: restrict_to_branch
      )
    end

    subject(:execute_integration) { asana_integration.execute(data) }

    context 'with restrict_to_branch' do
      let(:restrict_to_branch) { 'feature-branch, main' }
      let(:message) { 'fix #456789' }

      context 'when ref is in scope of restricted branches' do
        let(:ref) { 'main' }

        it 'calls the Asana integration' do
          expect(Gitlab::HTTP)
            .to receive(:post)
            .with("https://app.asana.com/api/1.0/tasks/456789/stories", anything).once.and_return(asana_task)
          expect(Gitlab::HTTP)
            .to receive(:put)
            .with("https://app.asana.com/api/1.0/tasks/456789", completed_message).once.and_return(asana_task)

          execute_integration
        end
      end

      context 'when ref is not in scope of restricted branches' do
        let(:ref) { 'mai' }

        it 'does not call the Asana integration' do
          expect(Gitlab::HTTP).not_to receive(:post)
          expect(Gitlab::HTTP).not_to receive(:put)

          execute_integration
        end
      end
    end

    context 'when creating a story' do
      let(:message) { "Message from commit. related to ##{gid}" }
      let(:expected_message) do
        {
          body: {
            text: "#{user.name} pushed to branch main of #{project.full_name} ( https://gitlab.com/ ): #{message}"
          },
          headers: { "Authorization" => "Bearer verySecret" }
        }
      end

      it 'calls Asana integration to create a story' do
        expect(Gitlab::HTTP)
          .to receive(:post)
          .with("https://app.asana.com/api/1.0/tasks/#{gid}/stories", expected_message).once.and_return(asana_task)

        execute_integration
      end
    end

    context 'when creating a story and closing a task' do
      let(:message) { 'fix #456789' }

      it 'calls Asana integration to create a story and close a task' do
        expect(Gitlab::HTTP)
          .to receive(:post)
          .with("https://app.asana.com/api/1.0/tasks/456789/stories", anything).once.and_return(asana_task)
        expect(Gitlab::HTTP)
          .to receive(:put)
          .with("https://app.asana.com/api/1.0/tasks/456789", completed_message).once.and_return(asana_task)

        execute_integration
      end
    end

    context 'when closing via url' do
      let(:message) { 'closes https://app.asana.com/19292/956299/42' }

      it 'calls Asana integration to close via url' do
        expect(Gitlab::HTTP)
          .to receive(:post)
          .with("https://app.asana.com/api/1.0/tasks/42/stories", anything).once.and_return(asana_task)
        expect(Gitlab::HTTP)
          .to receive(:put)
          .with("https://app.asana.com/api/1.0/tasks/42", completed_message).once.and_return(asana_task)

        execute_integration
      end
    end

    context 'with multiple matches per line' do
      let(:message) do
        <<-MESSAGE
        minor bigfix, refactoring, fixed #123 and Closes #456 work on #789
        ref https://app.asana.com/19292/956299/42 and closing https://app.asana.com/19292/956299/12,
        bug fixing and worked on #11, will be fixed
        in #222
        MESSAGE
      end

      it 'allows multiple matches per line' do
        expect(Gitlab::HTTP)
          .to receive(:post)
          .with("https://app.asana.com/api/1.0/tasks/123/stories", anything).once.and_return(asana_task)
        expect(Gitlab::HTTP)
          .to receive(:put)
          .with("https://app.asana.com/api/1.0/tasks/123", completed_message).once.and_return(asana_task)

        asana_task_2 = double(double(data: { gid: 456 }))

        expect(Gitlab::HTTP)
          .to receive(:post)
          .with("https://app.asana.com/api/1.0/tasks/456/stories", anything).once.and_return(asana_task_2)
        expect(Gitlab::HTTP)
          .to receive(:put)
          .with("https://app.asana.com/api/1.0/tasks/456", completed_message).once.and_return(asana_task_2)

        asana_task_3 = double(double(data: { gid: 789 }))

        expect(Gitlab::HTTP)
          .to receive(:post)
          .with("https://app.asana.com/api/1.0/tasks/789/stories", anything).once.and_return(asana_task_3)

        asana_task_4 = double(double(data: { gid: 42 }))

        expect(Gitlab::HTTP)
          .to receive(:post)
          .with("https://app.asana.com/api/1.0/tasks/42/stories", anything).once.and_return(asana_task_4)

        asana_task_5 = double(double(data: { gid: 12 }))

        expect(Gitlab::HTTP)
          .to receive(:post)
          .with("https://app.asana.com/api/1.0/tasks/12/stories", anything).once.and_return(asana_task_5)
        expect(Gitlab::HTTP)
          .to receive(:put)
          .with("https://app.asana.com/api/1.0/tasks/12", completed_message).once.and_return(asana_task_5)

        asana_task_5 = double(double(data: { gid: 11 }))

        expect(Gitlab::HTTP)
          .to receive(:post)
          .with("https://app.asana.com/api/1.0/tasks/11/stories", anything).once.and_return(asana_task_5)
        expect(Gitlab::HTTP)
          .not_to receive(:put)
          .with("https://app.asana.com/api/1.0/tasks/11", completed_message)

        asana_task_6 = double(double(data: { gid: 222 }))

        expect(Gitlab::HTTP)
          .to receive(:post)
          .with("https://app.asana.com/api/1.0/tasks/222/stories", anything).once.and_return(asana_task_6)
        expect(Gitlab::HTTP)
          .not_to receive(:put)
          .with("https://app.asana.com/api/1.0/tasks/222", completed_message)

        execute_integration
      end
    end

    context 'when processing a large commit message' do
      let(:message) { '#' * 2_000_000 }

      it 'has no backtracking issue' do
        expect do
          Timeout.timeout(1) do
            execute_integration
          end
        end.not_to raise_error
      end
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles

  describe '#test' do
    let(:asana_integration) { described_class.new(api_key: 'test') }
    let(:headers) { { "Authorization" => "Bearer test" } }

    subject(:test_integration) { asana_integration.test(nil) }

    context 'when authentication succeeds' do
      before do
        stub_request(:get, Integrations::Asana::PERSONAL_ACCESS_TOKEN_TEST_URL)
          .with(headers: headers)
          .to_return(status: [200, "Success"])
      end

      it 'returns a successful result' do
        result = test_integration

        expect(result[:success]).to be true
      end
    end

    context 'when authentication fails' do
      before do
        stub_request(:get, Integrations::Asana::PERSONAL_ACCESS_TOKEN_TEST_URL)
          .to_return(status: [401, 'Unauthorized'])
      end

      it 'returns an authorized result' do
        result = test_integration

        expect(result[:success]).to be false
        expect(result[:result]).to eq 'Unauthorized'
      end
    end
  end
end
