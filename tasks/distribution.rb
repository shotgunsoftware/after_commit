require 'jeweler'

Jeweler::Tasks.new do |gem|
  gem.name = 'after_commit'
  gem.summary = 'after_commit callback for ActiveRecord'
  gem.description = %Q{
    A Ruby on Rails plugin to add an after_commit callback. This can be used to trigger methods only after the entire transaction is complete.
  }
  gem.email = "pat@freelancing-gods.com"
  gem.homepage = "http://github.com/pat/after_commit"
  gem.authors = ["Nick Muerdter", "David Yip", "Pat Allan"]

  gem.files = FileList[
    'lib/**/*.rb',
    'LICENSE',
    'rails/**/*.rb',
    'README'
  ]
  gem.test_files = FileList[
    'test/**/*.rb'
  ]

  gem.add_dependency 'activerecord', '>= 1.15.6', '< 3.0.0'
  gem.add_development_dependency 'sqlite3-ruby'
end
