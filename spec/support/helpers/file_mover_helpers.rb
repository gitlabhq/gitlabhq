# frozen_string_literal: true

module FileMoverHelpers
  def stub_file_mover(file_path, stub_real_path: nil)
    file_name = File.basename(file_path)
    allow(Pathname).to receive(:new).and_call_original

    expect_next_instance_of(Pathname, a_string_including(file_name)) do |pathname|
      allow(pathname).to receive(:realpath) { stub_real_path || pathname.cleanpath }
    end
  end
end
