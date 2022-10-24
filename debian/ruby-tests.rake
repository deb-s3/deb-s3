require 'gem2deb/rake/testtask'

Gem2Deb::Rake::TestTask.new do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end
