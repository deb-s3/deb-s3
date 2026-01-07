$:.unshift File.expand_path("../lib", __FILE__)
require "deb/s3"

Gem::Specification.new do |gem|
  gem.name        = "deb-s3"
  gem.version     = Deb::S3::VERSION

  gem.author      = "Stefan Heitmüller"
  gem.email       = "stefan.heitmueller@gmx.com"
  gem.homepage    = "https://github.com/deb-s3/deb-s3"
  gem.summary     = "Easily create and manage an APT repository on S3."
  gem.description = gem.summary
  gem.license     = "MIT"
  gem.executables = "deb-s3"

  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|ext/|lib/)} }

  gem.required_ruby_version = '>= 2.7.0'

  gem.add_dependency "thor", "~> 1"
  gem.add_dependency "aws-sdk-s3", "~> 1"
  gem.add_development_dependency "minitest", "~> 5"
  gem.add_development_dependency "rake", "~> 12"
  gem.add_dependency "ostruct"
end
