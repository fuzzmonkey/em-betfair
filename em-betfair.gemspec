# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "em-betfair"
  s.version     = "0.2"
  s.authors     = ["George Sheppard"]
  s.email       = ["george@fuzzmonkey.co.uk"]
  s.homepage    = "https://github.com/fuzzmonkey/em-betfair"
  s.summary     = %q{Betfair API client using Eventmachine and EM-Http}
  s.description = %q{em-betfair is a work in progress evented client for the Betfair API}

  s.rubyforge_project = "em-betfair"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_runtime_dependency "eventmachine"
  s.add_runtime_dependency "em-http-request"
  s.add_runtime_dependency "haml"
  s.add_runtime_dependency "nokogiri"

end
