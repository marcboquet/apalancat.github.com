class SearchController < ApplicationController
  
  def index
    query = ActiveSupport::Multibyte::Unicode::normalize(params[:q], :kd).gsub(/[^\x00-\x7F]/,'')
    
    ## Regexp result for "Dexter s03e12": ["s03e12", nil, nil, "03", "12"]
    ##                         pre_match: "Dexter "
    # regexp to only match season and ep: /s?(\d+)[xe]?(\d*)/
    match = query.match(/(^(\d+[xe]\d+))*s?(\d+)\s*[xe]?(\d*)/)
    
    if match.nil?
      series_query = query.strip
    else
      query_ep = match.to_a
      num_season = query_ep[3].nil? ? nil : query_ep[3].to_i
      num_episode = query_ep[4].nil? ? nil : query_ep[4].to_i
      series_query = match.pre_match.strip.empty? ? match.post_match.strip : match.pre_match.strip
    end
    
    series = []
    unless series_query.empty?
      series = Series.fields(:title => 1).all(:title_searchable => /#{series_query}/i)
      if num_season.nil?
      series.concat Episode.where(:series_id => series.first.id).sort(:num_season.desc, :num_episode.desc).limit(10).all().collect {|ep| {:title_searchable => "#{series_query} #{"%d" % ep.num_season}x#{"%02d" % ep.num_episode}"} }
      else
        episodes = Episode.sort(:num_season => "desc", :num_episode => "desc").all(:num_season => num_season, :series_id.in => series.collect{|s|s.id})
        series = episodes.collect {|ep| {:title_searchable => "#{series_query} #{"%d" % ep.num_season}x#{"%02d" % ep.num_episode}"} }
      end
    end
    result = series << {:title=>"s #{num_season} e #{num_episode}"}
    #render :text =>'[{"title":"'+s.title+'","post":"'+s.title+'"}]'
    render :json => result.to_json
  end
  
  
end

