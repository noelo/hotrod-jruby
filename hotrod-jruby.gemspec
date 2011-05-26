# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'bundler/version'

Gem::Specification.new do |s|
      s.name = "hotrod-jruby"
    s.summary = "A jRuby wrapper for Infinispan's hot rod client"
    s.email = "noel.oconnor@gmail.com"
    s.homepage = "https://github.com/noelo/hotrod-jruby"
    s.description = "A jRuby wrapper for Infinispan's hot rod client"
    s.authors = ["Noel O'Connor"]
    s.require_path = 'lib'
	s.version = '1.0'
end
