# -*- encoding : utf-8 -*-
require File.expand_path('../../../spec_helper', __FILE__)
require 'deb/s3/utils'
require 'deb/s3/release'

describe Deb::S3::Release do
  def release_text(fields)
    fields.map { |k, v| "#{k}: #{v}" }.join("\n") + "\n"
  end

  describe "#parse" do
    it "reads Label from an existing Release" do
      rel = Deb::S3::Release.parse_release(release_text(
        "Origin" => "public jammy",
        "Label" => "public jammy",
        "Codename" => "jammy",
        "Suite" => "jammy",
        "Architectures" => "amd64",
        "Components" => "main",
      ))
      _(rel.label).must_equal "public jammy"
    end

    it "leaves Label nil when the Release has none" do
      rel = Deb::S3::Release.parse_release(release_text(
        "Codename" => "jammy",
        "Architectures" => "amd64",
        "Components" => "main",
      ))
      _(rel.label).must_be_nil
    end
  end

  describe "#generate" do
    it "emits Label when set" do
      rel = Deb::S3::Release.new
      rel.codename = "jammy"
      rel.origin = "public jammy"
      rel.label = "public jammy"
      rel.suite = "jammy"
      rel.architectures = ["amd64"]
      rel.components = ["main"]
      _(rel.generate).must_match(/^Label: public jammy$/)
    end

    it "omits the Label line entirely when unset" do
      rel = Deb::S3::Release.new
      rel.codename = "jammy"
      rel.architectures = ["amd64"]
      rel.components = ["main"]
      _(rel.generate).wont_match(/^Label:/)
    end

    it "round-trips an existing Label through parse and generate" do
      original = release_text(
        "Origin" => "public jammy",
        "Label" => "public jammy",
        "Codename" => "jammy",
        "Suite" => "jammy",
        "Architectures" => "amd64",
        "Components" => "main",
      )
      regenerated = Deb::S3::Release.parse_release(original).generate
      _(regenerated).must_match(/^Label: public jammy$/)
      _(regenerated).must_match(/^Origin: public jammy$/)
    end
  end
end
