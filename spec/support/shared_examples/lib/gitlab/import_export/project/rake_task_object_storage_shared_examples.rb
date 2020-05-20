# frozen_string_literal: true

RSpec.shared_examples 'rake task with disabled object_storage' do |service_class, method|
  it 'disables direct & background upload only for service call' do
    expect_next_instance_of(service_class) do |service|
      expect(service).to receive(:execute).and_wrap_original do |m|
        expect(Settings.uploads.object_store['enabled']).to eq(false)

        m.call
      end
    end

    expect(rake_task).to receive(method).and_wrap_original do |m, *args|
      expect(Settings.uploads.object_store['enabled']).to eq(true)
      expect(Settings.uploads.object_store).not_to receive(:[]=).with('enabled', false)

      m.call(*args)
    end

    subject
  end
end
