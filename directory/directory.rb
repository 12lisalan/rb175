require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  File.read "public/hello.html"
end