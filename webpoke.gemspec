# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'Webpoke/version'

Gem::Specification.new do |gem|
  gem.name          = "Webpoke"
  gem.version       = Webpoke::VERSION
  gem.authors       = ["Roberto Hidalgo"]
  gem.email         = ["un@rob.mx"]
  gem.description   = "A very simple REST API tester"
  gem.summary       = "I still have no idea what is this"
  gem.homepage      = "https://github.com/unRob/webpoke"
  gem.licenses      = ['WTFPL', 'GPLv2']
  gem.has_rdoc      = true

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  
  gem.add_runtime_dependency 'httparty'
  
end