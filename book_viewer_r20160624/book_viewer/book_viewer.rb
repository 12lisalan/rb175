require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

before do
  @contents = File.readlines("data/toc.txt")
end

helpers do
  def in_paragraphs(chapter)
    chapter.split("\n\n").map.with_index do |paragraph, index|
      "<p id='#{index+1}'>#{paragraph}</p>"
    end.join
  end
end
get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  chapter_name = @contents[number - 1]

  redirect "/" unless (1..@contents.size).cover? number

  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end


get "/search" do
  query = params[:query]
  @result = search

  erb :search
end

not_found do
  redirect "/"
end

# returns hash in format {number:title} of chapters containing
# search term
def search
  query = params[:query]
  result = {}
  @contents.each_with_index do |title, number|
    number = number + 1
    chapter = File.read("data/chp#{number}.txt")
    if chapter.include?(query)
      result[number] = title
    end
  end
  result
end
