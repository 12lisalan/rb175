require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  @entries = Dir.entries("public").reject{|x| x[0] == "."}
  erb :home
end

get "/descending" do
  @entries = Dir.entries("public").reject{|x| x[0] == "."}
  erb :descending
end