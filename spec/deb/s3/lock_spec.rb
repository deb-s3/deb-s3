# -*- encoding : utf-8 -*-
require File.expand_path('../../../spec_helper', __FILE__)
require 'deb/s3/lock'
require 'minitest/mock'

describe Deb::S3::Lock do
# describe :lock do
#   it 'creates a lock file' do
#     mock = MiniTest::Mock.new
#     mock.expect(:call, nil, 4.times.map {Object})
#     Deb::S3::Utils.stub :s3_store, mock do
#       Deb::S3::Lock.lock("stable")
#     end
#     mock.verify
#   end
# end

  describe :unlock do
    it 'deletes the lock file' do
      mock = MiniTest::Mock.new
      mock.expect(:call, nil, [String])
      Deb::S3::Utils.stub :s3_remove, mock do
        Deb::S3::Lock.unlock("stable")
      end
      mock.verify
    end
  end

  describe :current do
    before :each do
      mock = MiniTest::Mock.new
      mock.expect(:call, "alex@localhost", [String])
      Deb::S3::Utils.stub :s3_read, mock do
        @lock = Deb::S3::Lock.current("stable")
      end
    end

    it 'returns a lock object' do
      @lock.must_be_instance_of Deb::S3::Lock
    end

    it 'holds the user who currently holds the lock' do
      @lock.user.must_equal 'alex'
    end

    it 'holds the hostname from where the lock was set' do
      @lock.host.must_equal 'localhost'
    end
  end

end
