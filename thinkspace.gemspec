Gem::Specification.new do |spec|
	spec.name          = "AutomateAllTheThings"
	spec.version       = "2.5.0"
	spec.authors       = ["Rahul Prabhu"]
  spec.email         = ["rahuldprabhu@gmail.com"]

	spec.summary       = "A minimalist Jekyll theme"
	spec.homepage      = "https://tw3rp/net"
	spec.license       = "MIT"

	spec.metadata["plugin_type"] = "theme"

	spec.files         = `git ls-files -z`.split("\x0").select { |f| f.match(%r!^(assets|_layouts|_includes|_sass|(LICENSE|README)((\.(txt|md|markdown)|$)))!i) }

	spec.add_runtime_dependency "jekyll", "~> 3.8.5"

	spec.add_development_dependency "bundler", "> 1.15"
	spec.add_development_dependency "rake", "> 12.0"
end

