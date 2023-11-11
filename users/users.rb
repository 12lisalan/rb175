require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "yaml"

before do
  @info = YAML.load_file('users.yaml')
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end