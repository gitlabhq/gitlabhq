require 'spec_helper'

describe 'Gitlab::Satellite::Action' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  describe '#prepare_satellite!' do
    it 'should be able to fetch timeout from conf' do
      expect(Gitlab::Satellite::Action::DEFAULT_OPTIONS[:git_timeout]).to eq(30.seconds)
    end

    it 'create a repository with a parking branch and one remote: origin' do
      repo = project.satellite.repo

      #now lets dirty it up

      starting_remote_count = repo.git.list_remotes.size
      expect(starting_remote_count).to be >= 1
      #kind of hookey way to add a second remote
      origin_uri = repo.git.remote({v: true}).split(" ")[1]
    begin
      repo.git.remote({raise: true}, 'add', 'another-remote', origin_uri)
      repo.git.branch({raise: true}, 'a-new-branch')

      expect(repo.heads.size).to be > (starting_remote_count)
      expect(repo.git.remote().split(" ").size).to be > (starting_remote_count)
    rescue
    end

      repo.git.config({}, "user.name", "#{user.name} -- foo")
      repo.git.config({}, "user.email", "#{user.email} -- foo")
      expect(repo.config['user.name']).to eq("#{user.name} -- foo")
      expect(repo.config['user.email']).to eq("#{user.email} -- foo")


      #These must happen in the context of the satellite directory...
      satellite_action = Gitlab::Satellite::Action.new(user, project)
      project.satellite.lock {
        #Now clean it up, use send to get around prepare_satellite! being protected
        satellite_action.send(:prepare_satellite!, repo)
      }

      #verify it's clean
      heads = repo.heads.map(&:name)
      expect(heads.size).to eq(1)
      expect(heads.include?(Gitlab::Satellite::Satellite::PARKING_BRANCH)).to eq(true)
      remotes = repo.git.remote().split(' ')
      expect(remotes.size).to eq(1)
      expect(remotes.include?('origin')).to eq(true)
      expect(repo.config['user.name']).to eq(user.name)
      expect(repo.config['user.email']).to eq(user.email)
    end
  end

  describe '#in_locked_and_timed_satellite' do

    it 'should make use of a lockfile' do
      repo = project.satellite.repo
      called = false

      #set assumptions
      FileUtils.rm_f(project.satellite.lock_file)

      expect(File.exists?(project.satellite.lock_file)).to be_falsey

      satellite_action = Gitlab::Satellite::Action.new(user, project)
      satellite_action.send(:in_locked_and_timed_satellite) do |sat_repo|
        expect(repo).to eq(sat_repo)
        expect(File.exists? project.satellite.lock_file).to be_truthy
        called = true
      end

      expect(called).to be_truthy

    end

    it 'should be able to use the satellite after locking' do
      repo = project.satellite.repo
      called = false

      # Set base assumptions
      if File.exists? project.satellite.lock_file
        expect(FileLockStatusChecker.new(project.satellite.lock_file).flocked?).to be_falsey
      end

      satellite_action = Gitlab::Satellite::Action.new(user, project)
      satellite_action.send(:in_locked_and_timed_satellite) do |sat_repo|
        called = true
        expect(repo).to eq(sat_repo)
        expect(File.exists? project.satellite.lock_file).to be_truthy
        expect(FileLockStatusChecker.new(project.satellite.lock_file).flocked?).to be_truthy
      end

      expect(called).to be_truthy
      expect(FileLockStatusChecker.new(project.satellite.lock_file).flocked?).to be_falsey

    end

    class FileLockStatusChecker < File
      def flocked?(&block)
        status = flock LOCK_EX|LOCK_NB
        case status
          when false
            return true
          when 0
            begin
              block ? block.call : false
            ensure
              flock LOCK_UN
            end
          else
            raise SystemCallError, status
        end
      end
    end

  end
end
