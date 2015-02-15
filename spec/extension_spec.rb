require_relative "spec_helper"
require 'sequel'

context "pg-comment extension" do
	it "loads successfully" do
		expect do
			Sequel::Database.extension :pg_comment
			Sequel::Database.connect "mock://postgres"
		end.to_not raise_error
	end
end
