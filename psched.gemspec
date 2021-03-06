# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'psched/version'

Gem::Specification.new do |gem|
  gem.name          = "psched"
  gem.version       = Psched::VERSION
  gem.summary       = %q{Precise scheduling of recurring tasks}
  gem.description   = %q{Precise scheduling of recurring tasks using semaphores (not supported on Windows!)}
  gem.license       = "0BSD"
  gem.authors       = ["Paolo Bosetti"]
  gem.email         = "paolo.bosetti@unitn.it"
  gem.homepage      = "https://rubygems.org/gems/psched"

  gem.files         = `git ls-files`.split($/)

  `git submodule --quiet foreach --recursive pwd`.split($/).each do |submodule|
    submodule.sub!("#{Dir.pwd}/",'')

    Dir.chdir(submodule) do
      `git ls-files`.split($/).map do |subpath|
        gem.files << File.join(submodule,subpath)
      end
    end
  end
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
  gem.add_dependency 'ffi', '~>1.9.18'

  gem.add_development_dependency 'bundler', '~> 1.12'
  gem.add_development_dependency 'rake', '~> 12.0'
  gem.add_development_dependency 'rspec', '~> 3.7'
  gem.add_development_dependency 'rubygems-tasks', '~> 0.2'
  gem.add_development_dependency 'yard', '~> 0.9.12'
end
