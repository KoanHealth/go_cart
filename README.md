gocart
======

A tool and library for managing CSV and fixed-length format data files

## Prerequisites
* Ruby 1.9.3

## Install
    gem 'gocart'

## Usage

## Generate formatfile from schemafile
	gocart gen --schema schemafile.txt --format formatfile.rb
	gocart gen --schema schemafile.txt > formatfile.rb

## Generate formatfile from datafile (datafile must be CSV)
	gocart gen --data datafile.txt --format formatfile.rb
	gocart gen --data datafile.txt > formatfile.rb

## Generate formatfile from multiple datafiles (all datafiles must be CSV, headers recommended but not required)
	gocart gen --data *.txt --format formatfile.rb
	gocart gen --data *.txt > formatfile.rb

## Load datafile(s) into DB table(s) using formatfile (all datafiles must be CSV with headers)
	gocart run --format formatfile.rb --data datafile.txt
	gocart run --format formatfile.rb --data *.txt

## Load datafile(s) into DB table tablename using formatfile
	gocart run --format formatfile.rb --table tablename --data datafile.txt
	gocart run --format formatfile.rb --table tablename --data *.txt

## Create all tables (defined in formatfile) in the database
	./gocart.rb run --format formatfile.rb --create

## Create tablename table (defined in formatfile) in the database
	./gocart.rb run --format formatfile.rb --create --table tablename

## Copyright
(c) 2012 Koan Health. See LICENSE.txt for further details.