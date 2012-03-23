Gem::Specification.new do |s|
  s.name        = 'affilinet'
  s.version     = '0.1.0'
  s.date        = '2012-03-23'
  s.summary     = "This is a simple ruby wrapper around the Affilinet SOAP API for reports"
  s.description = ""
  s.authors     = ["Frank Eckert"]
  s.email       = 'frank.ecker@donovo.org'
  s.files       = ["lib/AffilinetApi.rb"]
  s.add_dependency(%q<ruby-hmac>, [">= 0"])
end
