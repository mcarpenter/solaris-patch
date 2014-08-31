Gem::Specification.new do |s|
  s.add_dependency('mechanize', '>= 1.0.0')
  s.authors = ['Martin Carpenter']
  s.date = Time.now.strftime('%Y-%m-%d')
  s.description = 'Provides methods to deal with Solaris patchdiag.xref and patches, including parsing patchdiag.xref, downloads from Oracle (patch and readme), patch version comparison, and generic patchdiag.xref manipulations such as seeking the latest non-obsolete version of a patch'
  s.email = 'mcarpenter@free.fr'
  s.extra_rdoc_files = %w{ LICENSE Rakefile README.rdoc }
  s.files = FileList['lib/**/*', 'test/**/*'].to_a
  s.has_rdoc = true
  s.homepage = 'http://mcarpenter.org/projects/solaris-patch'
  s.licenses = ['BSD']
  s.name = 'solaris-patch'
  s.platform = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = nil
  s.summary = 'Facilitate the manipulation of Solaris patches'
  s.test_files = FileList["{test}/**/test_*.rb"].to_a
  s.version = '1.0.3'
end

