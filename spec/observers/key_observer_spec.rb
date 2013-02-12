require 'spec_helper'

describe KeyObserver do
  before do
    @key = double('Key',
      identifier: 'admin_654654',
      key: '== a vaild ssh key',
      projects: [],
      is_deploy_key: false
    )

    @observer = KeyObserver.instance
  end

  context :after_save do
    it do
      GitoliteWorker.should_receive(:perform_async).with(:set_key, @key.identifier, @key.key, @key.projects.map(&:id))
      @observer.after_save(@key)
    end
  end

  context :after_destroy do
    it do
      GitoliteWorker.should_receive(:perform_async).with(:remove_key, @key.identifier, @key.projects.map(&:id))
      @observer.after_destroy(@key)
    end
  end
end
