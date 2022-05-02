# -*- encoding : utf-8 -*-
require "base64"
require "digest/md5"
require "etc"
require "socket"
require "tempfile"

class Deb::S3::Lock
  attr_reader :user
  attr_reader :host

  def initialize(user, host)
    @user = user
    @host = host
  end

  class << self
    #
    # 2-phase mutual lock mechanism based on `s3:CopyObject`.
    #
    # This logic isn't relying on S3's enhanced features like Object Lock
    # because it imposes some limitation on using other features like
    # S3 Cross-Region replication. This should work more than good enough 
    # with S3's strong read-after-write consistency which we can presume
    # in all region nowadays.
    #
    # This is relying on S3 to set object's ETag as object's MD5 if an
    # object isn't comprized from multiple parts. We'd be able to presume
    # it as the lock file is usually an object of some smaller bytes.
    #
    # acquire lock:
    # 1. call `s3:HeadObject` on final lock object
    #   1. If final lock object exists, restart from the beginning
    #   2. Otherwise, call `s3:PutObject` to create initial lock object
    # 2. Perform `s3:CopyObject` to copy from initial lock object
    #    to final lock object with specifying ETag/MD5 of the initial
    #    lock object
    #   1. If copy object fails as `PreconditionFailed`, restart
    #      from the beginning
    #   2. Otherwise, lock has been acquired
    #
    # release lock:
    # 1. remove final lock object by `s3:DeleteObject`
    #
    def lock(codename, component = nil, architecture = nil, cache_control = nil, max_attempts=60, max_wait_interval=10)
      lockbody = "#{Etc.getlogin}@#{Socket.gethostname}"
      initial_lockfile = initial_lock_path(codename, component, architecture, cache_control)
      final_lockfile = lock_path(codename, component, architecture, cache_control)

      md5_b64 = Base64.encode64(Digest::MD5.digest(lockbody))
      md5_hex = Digest::MD5.hexdigest(lockbody)
      max_attempts.times do |i|
        wait_interval = [(1<<i)/10, max_wait_interval].min
        if Deb::S3::Utils.s3_exists?(final_lockfile)
          lock = current(codename, component, architecture, cache_control)
          $stderr.puts("Repository is locked by another user: #{lock.user} at host #{lock.host} (phase-1)")
          $stderr.puts("Attempting to obtain a lock after #{wait_interval} secound(s).")
          sleep(wait_interval)
        else
          # upload the file
          Deb::S3::Utils.s3.put_object(
            bucket: Deb::S3::Utils.bucket,
            key: Deb::S3::Utils.s3_path(initial_lockfile),
            body: lockbody,
            content_type: "text/plain",
            content_md5: md5_b64,
            metadata: {
              "md5" => md5_hex,
            },
          )
          begin
            Deb::S3::Utils.s3.copy_object(
              bucket: Deb::S3::Utils.bucket,
              key: Deb::S3::Utils.s3_path(final_lockfile),
              copy_source: "/#{Deb::S3::Utils.bucket}/#{Deb::S3::Utils.s3_path(initial_lockfile)}",
              copy_source_if_match: md5_hex,
            )
            return
          rescue Aws::S3::Errors::PreconditionFailed => error
            lock = current(codename, component, architecture, cache_control)
            $stderr.puts("Repository is locked by another user: #{lock.user} at host #{lock.host} (phase-2)")
            $stderr.puts("Attempting to obtain a lock after #{wait_interval} second(s).")
            sleep(wait_interval)
          end
        end
      end
      # TODO: throw appropriate error class
      raise("Unable to obtain a lock after #{max_attempts}, giving up.")
    end

    def unlock(codename, component = nil, architecture = nil, cache_control = nil)
      Deb::S3::Utils.s3_remove(initial_lock_path(codename, component, architecture, cache_control))
      Deb::S3::Utils.s3_remove(lock_path(codename, component, architecture, cache_control))
    end

    def current(codename, component = nil, architecture = nil, cache_control = nil)
      lockbody = Deb::S3::Utils.s3_read(lock_path(codename, component, architecture, cache_control))
      if lockbody
        user, host = lockbody.to_s.split("@", 2)
        lock = Deb::S3::Lock.new(user, host)
      else
        lock = Deb::S3::Lock.new("unknown", "unknown")
      end
      lock
    end

    private
    def initial_lock_path(codename, component = nil, architecture = nil, cache_control = nil)
      "dists/#{codename}/lockfile.lock"
    end

    def lock_path(codename, component = nil, architecture = nil, cache_control = nil)
      #
      # Acquire repository lock at `codename` level to avoid race between concurrent upload attempts.
      #
      # * `deb-s3 upload --arch=all` touchs multiples of `dists/{codename}/{component}/binary-*/Packages*`
      # * All `deb-s3 upload` touchs `dists/{codename}/Release`
      #
      "dists/#{codename}/lockfile"
    end
  end
end
