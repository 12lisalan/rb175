require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  @title = "Some title"
  @content = File.readlines("data/toc.txt")
  erb :home
end

get "/chapters/1" do
  @title = "Chapter 1"
  @content = File.readlines("data/toc.txt")
  @chapter_1 = File.readlines("data/chp1.txt")
  erb :chapter
end
