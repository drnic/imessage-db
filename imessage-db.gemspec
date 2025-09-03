# frozen_string_literal: true

require_relative "lib/imessage/db/version"

Gem::Specification.new do |spec|
  spec.name = "imessage-db"
  spec.version = Imessage::Db::VERSION
  spec.authors = ["Dr Nic Williams"]
  spec.email = ["drnicwilliams@gmail.com"]

  spec.summary = "Rails-friendly ActiveRecord models and utilities for reading macOS Messages chat.db."
  spec.description = "imessage-db provides ActiveRecord models and helpers for reading chats, messages, handles, and attachments from the macOS Messages app database (~/Library/Messages/chat.db). Enables Rails apps to query and analyze iMessage/SMS data locally. Requires Full Disk Access. Read-only, single-user, local use only."
  spec.homepage = "https://github.com/drnic/imessage-db"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/drnic/imessage-db"
  spec.metadata["changelog_uri"] = "https://github.com/drnic/imessage-db/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 6.1"
  spec.add_dependency "railties", ">= 6.1"
  spec.add_dependency "sqlite3"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
