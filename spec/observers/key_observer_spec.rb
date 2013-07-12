require 'spec_helper'

describe KeyObserver do
  before do
    @key = create(:personal_key)

    @observer = KeyObserver.instance
  end

  context :after_create do
    it do
      GitlabShellWorker.should_receive(:perform_async).with(:add_key, @key.shell_id, @key.key)
      @observer.after_create(@key)
    end
  end

  context :after_destroy do
    it do
      GitlabShellWorker.should_receive(:perform_async).with(:remove_key, @key.shell_id, @key.key)
      @observer.after_destroy(@key)
    end
  end
end
