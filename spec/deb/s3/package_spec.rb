# -*- encoding : utf-8 -*-
require File.expand_path('../../../spec_helper', __FILE__)
require 'deb/s3/package'

EXPECTED_DESCRIPTION = "A platform for community discussion. Free, open, simple.\nThe description can have a continuation line.\n\nAnd blank lines.\n\nIf it wants to."

describe Deb::S3::Package do
  describe ".parse_string" do
    it "creates a Package object with the right attributes" do
      package = Deb::S3::Package.parse_string(File.read(fixture("Packages")))
      _(package.version).must_equal("0.9.8.3")
      assert_nil(package.epoch)
      _(package.iteration).must_equal("1396474125.12e4179.wheezy")
      _(package.full_version).must_equal("0.9.8.3-1396474125.12e4179.wheezy")
      _(package.description).must_equal(EXPECTED_DESCRIPTION)
    end
  end

  describe ".compare_versions" do
    it "compares simple versions" do
      _(Deb::S3::Package.compare_versions("1.0", "2.0")).must_equal(-1)
      _(Deb::S3::Package.compare_versions("2.0", "1.0")).must_equal(1)
      _(Deb::S3::Package.compare_versions("1.0", "1.0")).must_equal(0)
    end

    it "compares numeric segments properly (not lexicographic)" do
      _(Deb::S3::Package.compare_versions("1.10", "1.9")).must_equal(1)
      _(Deb::S3::Package.compare_versions("2.0.0", "1.99.99")).must_equal(1)
    end

    it "handles epochs" do
      _(Deb::S3::Package.compare_versions("1:1.0", "2.0")).must_equal(1)
      _(Deb::S3::Package.compare_versions("0:1.0", "1.0")).must_equal(0)
      _(Deb::S3::Package.compare_versions("1:0.1", "2:0.1")).must_equal(-1)
    end

    it "handles revisions" do
      _(Deb::S3::Package.compare_versions("1.0-1", "1.0-2")).must_equal(-1)
      _(Deb::S3::Package.compare_versions("1.0-1", "1.0-1")).must_equal(0)
      _(Deb::S3::Package.compare_versions("1.0-10", "1.0-9")).must_equal(1)
    end

    it "handles tilde (sorts before everything)" do
      _(Deb::S3::Package.compare_versions("1.0~beta", "1.0")).must_equal(-1)
      _(Deb::S3::Package.compare_versions("1.0~alpha", "1.0~beta")).must_equal(-1)
      _(Deb::S3::Package.compare_versions("1.0~rc1", "1.0")).must_equal(-1)
    end

    it "handles equal versions" do
      _(Deb::S3::Package.compare_versions("1.0-1", "1.0-1")).must_equal(0)
      _(Deb::S3::Package.compare_versions("1:2.3-4", "1:2.3-4")).must_equal(0)
    end

    it "handles real-world mina-style versions" do
      _(Deb::S3::Package.compare_versions(
        "3.0.8.4-1.1.4bullseye",
        "3.0.9.0-1.1.0bullseye"
      )).must_equal(-1)
    end
  end

  describe "#full_version" do
    it "returns nil if no version, epoch, iteration" do
      package = create_package
      assert_nil(package.full_version)
    end

    it "returns only the version if no epoch and no iteration" do
      package = create_package :version => "0.9.8"
      _(package.full_version).must_equal "0.9.8"
    end

    it "returns epoch:version if epoch and version" do
      epoch = Time.now.to_i
      package = create_package :version => "0.9.8", :epoch => epoch
      _(package.full_version).must_equal "#{epoch}:0.9.8"
    end

    it "returns version-iteration if version and iteration" do
      package = create_package :version => "0.9.8", :iteration => "2"
      _(package.full_version).must_equal "0.9.8-2"
    end

    it "returns epoch:version-iteration if epoch and version and iteration" do
      epoch = Time.now.to_i
      package = create_package :version => "0.9.8", :iteration => "2", :epoch => epoch
      _(package.full_version).must_equal "#{epoch}:0.9.8-2"
    end
  end
end
