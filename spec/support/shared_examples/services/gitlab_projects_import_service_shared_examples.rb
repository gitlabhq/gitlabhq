# frozen_string_literal: true

RSpec.shared_examples 'gitlab projects import validations' do
  context 'with an invalid path' do
    let(:path) { '/invalid-path/' }

    it 'returns an invalid project' do
      project = subject.execute

      expect(project).not_to be_persisted
      expect(project).not_to be_valid
    end
  end

  context 'with a valid path' do
    it 'creates a project' do
      project = subject.execute

      expect(project).to be_persisted
      expect(project).to be_valid
    end
  end

  context 'override params' do
    it 'stores them as import data when passed' do
      project = described_class
                  .new(namespace.owner, import_params, description: 'Hello')
                  .execute

      expect(project.import_data.data['override_params']['description']).to eq('Hello')
    end
  end

  context 'when there is a project with the same path' do
    let(:existing_project) { create(:project, namespace: namespace) }
    let(:path) { existing_project.path}

    it 'does not create the project' do
      project = subject.execute

      expect(project).to be_invalid
      expect(project).not_to be_persisted
    end

    context 'when overwrite param is set' do
      let(:overwrite) { true }

      it 'creates a project in a temporary full_path' do
        project = subject.execute

        expect(project).to be_valid
        expect(project).to be_persisted
      end
    end
  end

  context 'when measurable params are provided' do
    let(:base_log_data) do
      base_log_data = {
        class: described_class.name,
        current_user: namespace.owner.name,
        project_full_path: "#{namespace.full_path}/#{path}"
      }
      base_log_data.merge!({ import_type: 'gitlab_project', file_path: import_params[:file].path }) if import_params[:file]

      base_log_data
    end

    subject { described_class.new(namespace.owner, import_params) }

    context 'when measurement is enabled' do
      let(:logger) { double(:logger) }
      let(:measurable_options) do
        {
          measurement_enabled: true,
          measurement_logger: logger
        }
      end

      before do
        allow(logger).to receive(:info)
      end

      it 'measure service execution with Gitlab::Utils::Measuring' do
        expect(Gitlab::Utils::Measuring).to receive(:execute_with).with(true, logger, base_log_data).and_call_original
        expect_next_instance_of(Gitlab::Utils::Measuring) do |measuring|
          expect(measuring).to receive(:with_measuring).and_call_original
        end

        subject.execute(measurable_options)
      end
    end
    context 'when measurement is disabled' do
      let(:measurable_options) do
        {
          measurement_enabled: false
        }
      end

      it 'does not measure service execution' do
        expect(Gitlab::Utils::Measuring).to receive(:execute_with).with(false, nil, base_log_data).and_call_original
        expect(Gitlab::Utils::Measuring).not_to receive(:new)

        subject.execute(measurable_options)
      end
    end
  end
end
