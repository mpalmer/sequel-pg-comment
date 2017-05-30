$:.push File.expand_path("../lib", __FILE__)
require 'sequel/extensions/pg_comment/version'
require 'date'

Gem::Specification.new do |s|
	s.name = "sequel-pg-comment"

	s.version = Sequel::Postgres::Comment::VERSION
	s.date    = '2017-05-30'

	s.platform = Gem::Platform::RUBY

	s.homepage = "http://theshed.hezmatt.org/sequel-pg-comment"
	s.summary = "Set comments on PgSQL objects from seuqel migrations"
	s.authors = ["Matt Palmer"]

	s.extra_rdoc_files = ["README.md"]
	s.files = `git ls-files -z`.split("\0")

	s.add_runtime_dependency "git-version-bump", "~> 0.10"
	s.add_runtime_dependency "sequel"

	s.add_development_dependency 'bundler'
	s.add_development_dependency 'github-release'
	s.add_development_dependency 'guard-spork'
	s.add_development_dependency 'guard-rspec'
	# Needed for guard
	s.add_development_dependency 'rb-inotify', '~> 0.9'
	if RUBY_VERSION =~ /^1\./
		s.add_development_dependency 'pry-debugger'
	else
		s.add_development_dependency 'pry-byebug'
	end
	s.add_development_dependency 'rake', '~> 10.4', '>= 10.4.2'
	s.add_development_dependency 'redcarpet'
	s.add_development_dependency 'rspec', '~> 3.0'
	s.add_development_dependency 'yard'
end
