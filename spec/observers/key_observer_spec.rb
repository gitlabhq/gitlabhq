require 'spec_helper'

describe KeyObserver do
  before do
    @key = double('Key',
      shell_id: 'key-32',
      key: '== a vaild ssh key',
      projects: [],
      is_deploy_key: false
    )

    @observer = KeyObserver.instance
  end

  context :after_save do
    it do
      GitoliteWorker.should_receive(:perform_async).with(:add_key, @key.shell_id, @key.key)
      @observer.after_save(@key)
    end
  end

  context :after_destroy do
    it do
      GitoliteWorker.should_receive(:perform_async).with(:remove_key, @key.shell_id, @key.key)
      @observer.after_destroy(@key)
    end
  end
end
