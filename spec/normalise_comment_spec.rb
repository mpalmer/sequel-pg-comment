require_relative 'spec_helper'
require 'sequel'
require 'sequel/extensions/pg_comment'

context "Sequel::Postgres::Comment.normalise_comment" do
	def nc(s)
		Sequel::Postgres::Comment.normalise_comment(s)
	end

	it "does nothing to a string with no leading whitespace" do
		expect(nc("foo\nbar\nbaz")).to eq("foo\nbar\nbaz")
	end

	it "strips leading empty lines" do
		expect(nc("\n\n\nfoo\nbar\nbaz")).to eq("foo\nbar\nbaz")
	end

	it "strips trailing empty lines" do
		expect(nc("foo\nbar\nbaz\n\n\n")).to eq("foo\nbar\nbaz")
	end

	it "strips leading whitespace from all lines" do
		expect(nc("  foo\n  bar\n  baz")).to eq("foo\nbar\nbaz")
	end

	it "correctly handles intermediate empty lines" do
		expect(nc("  foo\n  bar\n\n  baz")).to eq("foo\nbar\n\nbaz")
	end

	it "ignores different leading whitespace" do
		expect(nc("  foo\n  bar\n\t  baz")).to eq("foo\nbar\n\t  baz")
	end

	it "partially truncates extra-whitespaced lines" do
		expect(nc("  foo\n  bar\n    baz")).to eq("foo\nbar\n  baz")
	end

	it "handles everything at once" do
		expect(nc(<<-EOF)).to eq("foo\n\t  bar\n  baz")

			foo
				  bar
			  baz


		EOF
	end
end
